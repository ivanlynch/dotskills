#!/usr/bin/env bash
# Operaciones atómicas y fail-closed sobre el archivo ejecutable del plan
# (el .txt generado por plan_state.sh export-file). Sin dependencias
# externas: texto plano, líneas con tag de tipo separadas por TAB.
set -euo pipefail

TAB=$'\t'
STATUSES=(PENDING IN_PROGRESS DONE BLOCKED)

err() { echo "ERROR: $*" >&2; exit 1; }
in_list() { local n="$1"; shift; for x in "$@"; do [ "$x" = "$n" ] && return 0; done; return 1; }
sanitize() { printf '%s' "$1" | tr '\t\n' '  '; }

require_file() {
  [ -f "$1" ] || err "No existe el archivo de plan: $1"
}

upsert_line() {
  local path="$1" prefix="$2" new_line="$3" tmp found=0
  tmp="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$prefix"*) printf '%s\n' "$new_line" >> "$tmp"; found=1 ;; *) printf '%s\n' "$line" >> "$tmp" ;; esac
  done < "$path"
  [ "$found" -eq 1 ] || printf '%s\n' "$new_line" >> "$tmp"
  mv "$tmp" "$path"
}

meta_get() { awk -F'\t' -v k="$2" '$1=="META" && $2==k {print $3}' "$1"; }
meta_set() { upsert_line "$1" "META${TAB}$2${TAB}" "META${TAB}$2${TAB}$3"; }
touch_updated_at() { meta_set "$1" updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

task_ids() { awk -F'\t' '$1=="TASK"{print $2}' "$1"; }
task_line() { awk -F'\t' -v id="$2" '$1=="TASK" && $2==id' "$1"; }
task_exists() { [ -n "$(task_line "$1" "$2")" ]; }
task_field() {
  local idx
  case "$3" in
    order) idx=3 ;; source_node_id) idx=4 ;; title) idx=5 ;; description) idx=6 ;;
    status) idx=7 ;; evidence) idx=8 ;; blocked_reason) idx=9 ;; started_at) idx=10 ;; completed_at) idx=11 ;;
    *) err "campo desconocido: $3" ;;
  esac
  task_line "$1" "$2" | awk -F'\t' -v i="$idx" '{print $i}'
}
set_task() {
  local path="$1" id="$2" order="$3" source="$4" title="$5" desc="$6" status="$7" evidence="$8" reason="$9" started="${10}" completed="${11}"
  upsert_line "$path" "TASK${TAB}${id}${TAB}" "TASK${TAB}${id}${TAB}${order}${TAB}${source}${TAB}${title}${TAB}${desc}${TAB}${status}${TAB}${evidence}${TAB}${reason}${TAB}${started}${TAB}${completed}"
}
task_dependencies() { awk -F'\t' -v id="$2" '$1=="DEP" && $2==id {print $3}' "$1"; }

dependencies_done() {
  local path="$1" id="$2" dep
  while IFS= read -r dep; do
    [ -n "$dep" ] || continue
    [ "$(task_field "$path" "$dep" status)" = "DONE" ] || return 1
  done <<< "$(task_dependencies "$path" "$id")"
  return 0
}

# --- validación --------------------------------------------------------

validate_plan() {
  local path="$1" errors=0
  [ "$(meta_get "$path" schema_version)" = "1" ] || { echo "schema_version debe ser 1."; errors=1; }
  [ "$(meta_get "$path" kind)" = "implementation-plan" ] || { echo "kind debe ser implementation-plan."; errors=1; }
  [ -n "$(meta_get "$path" ticket)" ] || { echo "ticket es obligatorio."; errors=1; }

  local ids; ids="$(task_ids "$path")"
  [ -n "$ids" ] || { echo "tasks debe ser una lista no vacía."; echo "__FATAL__"; return; }

  local dup; dup="$(printf '%s\n' "$ids" | sort | uniq -d)"
  [ -z "$dup" ] || { echo "Tarea duplicada: $(echo "$dup" | tr '\n' ' ')"; errors=1; }

  local id status order title desc evidence reason active=0
  active=0
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    status="$(task_field "$path" "$id" status)"
    order="$(task_field "$path" "$id" order)"
    title="$(task_field "$path" "$id" title)"
    desc="$(task_field "$path" "$id" description)"
    evidence="$(task_field "$path" "$id" evidence)"
    reason="$(task_field "$path" "$id" blocked_reason)"
    in_list "$status" "${STATUSES[@]}" || { echo "La tarea $id tiene status inválido."; errors=1; }
    case "$order" in ''|*[!0-9]*) echo "La tarea $id requiere un order positivo."; errors=1 ;; 0) echo "La tarea $id requiere un order positivo."; errors=1 ;; esac
    [ -n "$title" ] && [ -n "$desc" ] || { echo "La tarea $id requiere título y descripción."; errors=1; }
    [ "$status" = "IN_PROGRESS" ] && active=$((active + 1))
    if [ "$status" = "DONE" ] && [ -z "$evidence" ]; then echo "La tarea $id está DONE sin evidencia."; errors=1; fi
    if [ "$status" = "BLOCKED" ] && [ -z "$reason" ]; then echo "La tarea $id está BLOCKED sin motivo."; errors=1; fi
  done <<< "$ids"

  local dep
  while IFS=$'\t' read -r _tag task_id dep; do
    [ -n "${dep:-}" ] || continue
    if ! printf '%s\n' "$ids" | grep -qx "$dep"; then echo "La dependencia $dep no existe."; errors=1; fi
    [ "$dep" != "$task_id" ] || { echo "La tarea $task_id no puede depender de sí misma."; errors=1; }
  done < <(awk -F'\t' '$1=="DEP"' "$path")

  [ "$active" -le 1 ] || { echo "Solo puede existir una tarea IN_PROGRESS."; errors=1; }
  if [ "$(meta_get "$path" execution_status)" = "COMPLETE" ]; then
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      [ "$(task_field "$path" "$id" status)" = "DONE" ] || { echo "execution_status COMPLETE requiere todas las tareas DONE."; errors=1; break; }
    done <<< "$ids"
  fi
  [ "$errors" -eq 0 ]
}

require_valid() {
  local out; out="$(validate_plan "$1" || true)"
  [ -z "$out" ] || err "Archivo de plan inválido: $(echo "$out" | tr '\n' '|')"
}

# --- comandos ------------------------------------------------------------

cmd_validate() {
  require_file "$1"; require_valid "$1"
  local count; count="$(task_ids "$1" | grep -c . || true)"
  echo "validate: execution_status=$(meta_get "$1" execution_status) task_count=$count"
}

cmd_next() {
  local path="$1"; require_file "$path"; require_valid "$path"
  local id all_done=1
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ "$(task_field "$path" "$id" status)" = "DONE" ] || { all_done=0; break; }
  done <<< "$(task_ids "$path")"
  if [ "$all_done" -eq 1 ]; then echo "next: action=PLAN_COMPLETE execution_status=COMPLETE"; return 0; fi

  local blocked=()
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ "$(task_field "$path" "$id" status)" = "BLOCKED" ] && blocked+=("$id")
  done <<< "$(task_ids "$path")"
  if [ ${#blocked[@]} -gt 0 ]; then echo "next: action=BLOCKED blocked_tasks=${blocked[*]}"; return 0; fi

  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if [ "$(task_field "$path" "$id" status)" = "PENDING" ] && dependencies_done "$path" "$id"; then
      echo "next: action=IMPLEMENT_TASK task_id=$id title=$(task_field "$path" "$id" title)"
      return 0
    fi
  done <<< "$(task_ids "$path")"
  echo "next: action=WAIT_DEPENDENCY"
}

cmd_start() {
  local path="$1"; shift
  local task_id=""
  while [ $# -gt 0 ]; do case "$1" in --task-id) task_id="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  require_file "$path"; require_valid "$path"
  task_exists "$path" "$task_id" || err "No existe la tarea $task_id."
  [ "$(task_field "$path" "$task_id" status)" = "PENDING" ] || err "La tarea $task_id debe estar PENDING para iniciar."
  dependencies_done "$path" "$task_id" || err "Las dependencias de $task_id no están DONE."
  set_task "$path" "$task_id" "$(task_field "$path" "$task_id" order)" "$(task_field "$path" "$task_id" source_node_id)" \
    "$(task_field "$path" "$task_id" title)" "$(task_field "$path" "$task_id" description)" IN_PROGRESS "" "" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ""
  touch_updated_at "$path"
  require_valid "$path"
  echo "start: action=IMPLEMENT_TASK task_id=$task_id"
}

cmd_complete() {
  local path="$1"; shift
  local task_id="" evidence=""
  while [ $# -gt 0 ]; do case "$1" in --task-id) task_id="$2"; shift 2 ;; --evidence) evidence="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  require_file "$path"; require_valid "$path"
  task_exists "$path" "$task_id" || err "No existe la tarea $task_id."
  [ "$(task_field "$path" "$task_id" status)" = "IN_PROGRESS" ] || err "La tarea $task_id debe estar IN_PROGRESS para completarse."
  [ -n "$evidence" ] || err "Se requiere evidencia no vacía."
  set_task "$path" "$task_id" "$(task_field "$path" "$task_id" order)" "$(task_field "$path" "$task_id" source_node_id)" \
    "$(task_field "$path" "$task_id" title)" "$(task_field "$path" "$task_id" description)" DONE "$(sanitize "$evidence")" "" \
    "$(task_field "$path" "$task_id" started_at)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local all_done=1 id
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ "$(task_field "$path" "$id" status)" = "DONE" ] || { all_done=0; break; }
  done <<< "$(task_ids "$path")"
  [ "$all_done" -eq 1 ] && meta_set "$path" execution_status COMPLETE
  touch_updated_at "$path"
  require_valid "$path"
  echo "complete: action=DONE task_id=$task_id execution_status=$(meta_get "$path" execution_status)"
}

cmd_block() {
  local path="$1"; shift
  local task_id="" reason=""
  while [ $# -gt 0 ]; do case "$1" in --task-id) task_id="$2"; shift 2 ;; --reason) reason="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  require_file "$path"; require_valid "$path"
  task_exists "$path" "$task_id" || err "No existe la tarea $task_id."
  local status; status="$(task_field "$path" "$task_id" status)"
  [ "$status" = "PENDING" ] || [ "$status" = "IN_PROGRESS" ] || err "La tarea $task_id no puede bloquearse desde $status."
  [ -n "$reason" ] || err "Se requiere un motivo no vacío."
  set_task "$path" "$task_id" "$(task_field "$path" "$task_id" order)" "$(task_field "$path" "$task_id" source_node_id)" \
    "$(task_field "$path" "$task_id" title)" "$(task_field "$path" "$task_id" description)" BLOCKED "" "$(sanitize "$reason")" \
    "$(task_field "$path" "$task_id" started_at)" ""
  touch_updated_at "$path"
  require_valid "$path"
  echo "block: action=RESOLVE_BLOCKER task_id=$task_id"
}

usage() {
  cat >&2 <<'EOF'
Uso: plan_file.sh <comando> <plan_file> ...
  validate <plan_file>
  next <plan_file>
  start <plan_file> --task-id <id>
  complete <plan_file> --task-id <id> --evidence <t>
  block <plan_file> --task-id <id> --reason <t>
EOF
  exit 2
}

main() {
  local command="${1:-}"; [ -n "$command" ] || usage; shift
  [ $# -ge 1 ] || usage
  local path="$1"; shift
  case "$command" in
    validate) cmd_validate "$path" ;;
    next) cmd_next "$path" ;;
    start) cmd_start "$path" "$@" ;;
    complete) cmd_complete "$path" "$@" ;;
    block) cmd_block "$path" "$@" ;;
    *) usage ;;
  esac
}

main "$@"
