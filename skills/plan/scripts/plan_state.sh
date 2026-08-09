#!/usr/bin/env bash
# Estado fail-closed para la skill /plan. Sin dependencias externas: texto
# plano, un archivo por ticket, líneas con tag de tipo separadas por TAB.
set -euo pipefail

TAB=$'\t'
PLAN_STATUSES=(IN_PROGRESS COMPLETE BLOCKED)
TASK_STATUSES=(READY BLOCKED)

err() { echo "ERROR: $*" >&2; exit 1; }

in_list() { local n="$1"; shift; for x in "$@"; do [ "$x" = "$n" ] && return 0; done; return 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -d' ' -f1
  else err "Se necesita sha256sum o shasum."; fi
}

sanitize() { printf '%s' "$1" | tr '\t\n' '  '; }
project_hash() { pwd | sha256_of | cut -c1-12; }

normalize_issue_id() {
  local raw="$1" id
  id="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$id" ] || err "ID de issue vacío."
  case "$id" in *[[:space:]]*|*/*|*'\'*) err "ID de issue inválido: '$raw'." ;; esac
  printf '%s' "$id"
}

slug_for_filename() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '-' | tr 'A-Z' 'a-z' | sed -e 's/^-*//' -e 's/-*$//'
}

# Debe coincidir exactamente con analizar-alcance/scripts/workflow_state.sh:
# ambos scripts necesitan calcular la misma ruta para poder leerse.
workflow_state_path() {
  local slug; slug="$(slug_for_filename "$1")"
  [ -n "$slug" ] || slug="issue"
  printf '%s/cocinar-%s-%s-state.txt' "${TMPDIR:-/tmp}" "$slug" "$(project_hash)"
}

state_path() {
  local slug; slug="$(slug_for_filename "$1")"
  [ -n "$slug" ] || slug="issue"
  printf '%s/plan-%s-%s-state.txt' "${TMPDIR:-/tmp}" "$slug" "$(project_hash)"
}

require_state() {
  local path; path="$(state_path "$1")"
  [ -f "$path" ] || err "No existe estado de plan para $1. Ejecuta init primero."
  printf '%s' "$path"
}

upsert_line() {
  local path="$1" prefix="$2" new_line="$3" tmp found=0
  tmp="$(mktemp)"
  if [ -f "$path" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in "$prefix"*) printf '%s\n' "$new_line" >> "$tmp"; found=1 ;; *) printf '%s\n' "$line" >> "$tmp" ;; esac
    done < "$path"
  fi
  [ "$found" -eq 1 ] || printf '%s\n' "$new_line" >> "$tmp"
  mv "$tmp" "$path"
}

append_line() { printf '%s\n' "$2" >> "$1"; }

get_field() {
  local path="$1" prefix="$2" field="$3"
  [ -f "$path" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$prefix"*) printf '%s' "$line" | awk -F'\t' -v f="$field" '{print $f}'; return 0 ;; esac
  done < "$path"
}

meta_get() { get_field "$1" "META${TAB}$2${TAB}" 3; }
meta_set() { upsert_line "$1" "META${TAB}$2${TAB}" "META${TAB}$2${TAB}$3"; }
touch_updated_at() { meta_set "$1" updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

work_item_ids() { awk -F'\t' '$1=="WORKITEM"{print $2}' "$1"; }
work_item_title() { awk -F'\t' -v id="$2" '$1=="WORKITEM" && $2==id {print $3}' "$1"; }
work_item_exists() { [ -n "$(work_item_title "$1" "$2")" ]; }
work_item_criteria() { awk -F'\t' -v id="$2" '$1=="WORKCRIT" && $2==id {print $3}' "$1"; }

task_ids() { awk -F'\t' '$1=="TASK"{print $2}' "$1"; }
task_line() { awk -F'\t' -v id="$2" '$1=="TASK" && $2==id' "$1"; }
task_exists() { [ -n "$(task_line "$1" "$2")" ]; }
task_field() {
  local idx
  case "$3" in source_node_id) idx=3 ;; title) idx=4 ;; description) idx=5 ;; status) idx=6 ;; blocked_reason) idx=7 ;; created_at) idx=8 ;; updated_at) idx=9 ;; *) err "campo desconocido: $3" ;; esac
  task_line "$1" "$2" | awk -F'\t' -v i="$idx" '{print $i}'
}
set_task() {
  local path="$1" id="$2" source="$3" title="$4" desc="$5" status="$6" reason="$7" created="$8" updated="$9"
  upsert_line "$path" "TASK${TAB}${id}${TAB}" "TASK${TAB}${id}${TAB}${source}${TAB}${title}${TAB}${desc}${TAB}${status}${TAB}${reason}${TAB}${created}${TAB}${updated}"
}
task_steps() { awk -F'\t' -v id="$2" '$1=="STEP" && $2==id {print $3}' "$1"; }
task_verifications() { awk -F'\t' -v id="$2" '$1=="VERIFY" && $2==id {print $3}' "$1"; }
task_dependencies() { awk -F'\t' -v id="$2" '$1=="DEP" && $2==id {print $3}' "$1"; }

planned_items() { awk -F'\t' '$1=="PLANNED"{print $2}' "$1"; }
is_planned() { planned_items "$1" | grep -qx "$2"; }

next_task_id() {
  local n; n="$(task_ids "$1" | wc -l | tr -d ' ')"
  printf 'task-%03d' "$((n + 1))"
}

# --- validación --------------------------------------------------------

validate_state() {
  local path="$1" errors=0
  local status; status="$(meta_get "$path" status)"
  in_list "$status" "${PLAN_STATUSES[@]}" || { echo "status de plan inválido."; errors=1; }

  local item_ids; item_ids="$(work_item_ids "$path")"
  local task_id source title desc t_status
  while IFS= read -r task_id; do
    [ -n "$task_id" ] || continue
    source="$(task_field "$path" "$task_id" source_node_id)"
    title="$(task_field "$path" "$task_id" title)"
    desc="$(task_field "$path" "$task_id" description)"
    t_status="$(task_field "$path" "$task_id" status)"
    if ! printf '%s\n' "$item_ids" | grep -qx "$source"; then
      echo "La tarea $task_id referencia un work item inexistente."; errors=1
    fi
    in_list "$t_status" "${TASK_STATUSES[@]}" || { echo "La tarea $task_id tiene status inválido."; errors=1; }
    [ -n "$title" ] && [ -n "$desc" ] || { echo "La tarea $task_id requiere título y descripción."; errors=1; }
    [ -n "$(task_steps "$path" "$task_id" | head -1)" ] || { echo "La tarea $task_id requiere pasos de implementación."; errors=1; }
    [ -n "$(task_verifications "$path" "$task_id" | head -1)" ] || { echo "La tarea $task_id requiere verificaciones."; errors=1; }
    if [ "$t_status" = "BLOCKED" ] && [ -z "$(task_field "$path" "$task_id" blocked_reason)" ]; then
      echo "La tarea $task_id está BLOCKED sin motivo."; errors=1
    fi
  done <<< "$(task_ids "$path")"

  local planned; planned="$(planned_items "$path")"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    printf '%s\n' "$item_ids" | grep -qx "$p" || { echo "planned_work_items contiene referencias inválidas."; errors=1; }
  done <<< "$planned"

  if [ "$status" = "COMPLETE" ]; then
    local missing; missing="$(comm -23 <(printf '%s\n' "$item_ids" | sort -u) <(printf '%s\n' "$planned" | sort -u) 2>/dev/null | grep -c . || true)"
    [ "$missing" -eq 0 ] || { echo "El plan está COMPLETE pero hay work items sin cerrar."; errors=1; }
    while IFS= read -r task_id; do
      [ -n "$task_id" ] || continue
      [ "$(task_field "$path" "$task_id" status)" = "READY" ] || { echo "El plan está COMPLETE pero hay tareas no listas."; errors=1; }
    done <<< "$(task_ids "$path")"
  fi
  [ "$errors" -eq 0 ]
}

require_valid() {
  local out; out="$(validate_state "$1" || true)"
  [ -z "$out" ] || err "Estado inválido: $(echo "$out" | tr '\n' '|')"
}

# --- import del scope confirmado de analizar-alcance --------------------

import_scope() {
  # Lee el estado (ya plano) de workflow_state.sh para el mismo ticket y
  # proyecto; exige scope_analysis CONFIRMED con todos los nodos DONE.
  local ticket="$1" wpath; wpath="$(workflow_state_path "$ticket")"
  [ -f "$wpath" ] || err "No hay análisis de alcance para $ticket. Corré /analizar-alcance primero."
  local scope_status; scope_status="$(awk -F'\t' '$1=="SCOPEMETA" && $2=="status"{print $3}' "$wpath")"
  [ "$scope_status" = "CONFIRMED" ] || err "scope_analysis de $ticket no está CONFIRMED todavía."
  local objective; objective="$(awk -F'\t' '$1=="SCOPEMETA" && $2=="objective"{print $3}' "$wpath")"
  [ -n "$objective" ] || err "scope_analysis.objective está vacío."

  local ids; ids="$(awk -F'\t' '$1=="ITEM" && $5=="APTO_PARA_IMPLEMENTAR"{print $2}' "$wpath")"
  [ -n "$ids" ] || err "No hay work items con verdict APTO_PARA_IMPLEMENTAR en $ticket."

  local id title
  echo "$objective|$ids"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    title="$(awk -F'\t' -v i="$id" '$1=="ITEM" && $2==i{print $3}' "$wpath")"
    echo "WORKITEM${TAB}${id}${TAB}${title}"
    awk -F'\t' -v i="$id" '$1=="CRITERION" && $2==i{print "WORKCRIT\t"$2"\t"$3}' "$wpath"
  done <<< "$ids"
}

# --- comandos ------------------------------------------------------------

cmd_init() {
  local ticket="$1" path; path="$(state_path "$ticket")"
  if [ -f "$path" ]; then
    require_valid "$path"
    echo "$ticket: plan ya inicializado ($(meta_get "$path" status)) en $path"
    return 0
  fi
  local imported objective ids now
  imported="$(import_scope "$ticket")"
  objective="$(echo "$imported" | head -1 | cut -d'|' -f1)"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  {
    printf 'META%sticket%s%s\n' "$TAB" "$TAB" "$ticket"
    printf 'META%sproject%s%s\n' "$TAB" "$TAB" "$(pwd)"
    printf 'META%screated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'META%supdated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'META%sstatus%sIN_PROGRESS\n' "$TAB" "$TAB"
    printf 'META%sobjective%s%s\n' "$TAB" "$TAB" "$objective"
    echo "$imported" | tail -n +2
  } > "$path"
  echo "$ticket: plan inicializado en $path"
}

cmd_validate() {
  local path; path="$(require_state "$1")"
  require_valid "$path"
  echo "$1: VALID status=$(meta_get "$path" status) state=$path"
}

cmd_next() {
  local ticket="$1" path; path="$(require_state "$ticket")"
  require_valid "$path"
  local id
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ! is_planned "$path" "$id"; then
      local has_task=0
      while IFS= read -r task_id; do
        [ "$(task_field "$path" "$task_id" source_node_id)" = "$id" ] && has_task=1
      done <<< "$(task_ids "$path")"
      if [ "$has_task" -eq 1 ]; then
        echo "$ticket: action=REVIEW_WORK_ITEM work_item=$id"
      else
        echo "$ticket: action=CREATE_TICKET work_item=$id"
      fi
      return 0
    fi
  done <<< "$(work_item_ids "$path")"
  if [ "$(meta_get "$path" status)" = "COMPLETE" ]; then
    echo "$ticket: action=PLAN_COMPLETE next_phase=implementacion"
  else
    echo "$ticket: action=FINALIZE_PLAN next_phase=plan"
  fi
}

cmd_task_add() {
  local ticket="$1"; shift
  local source_node_id="" title="" description="" steps=() verifications=() dependencies=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --source-node-id) source_node_id="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --implementation-step) steps+=("$2"); shift 2 ;;
      --verification) verifications+=("$2"); shift 2 ;;
      --depends-on) dependencies+=("$2"); shift 2 ;;
      *) err "Argumento desconocido: $1" ;;
    esac
  done
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  [ "$(meta_get "$path" status)" = "IN_PROGRESS" ] || err "Solo se pueden agregar tareas mientras el plan está IN_PROGRESS."
  work_item_exists "$path" "$source_node_id" || err "No existe el work item $source_node_id."
  [ ${#steps[@]} -gt 0 ] || err "Se requiere al menos un --implementation-step."
  [ ${#verifications[@]} -gt 0 ] || err "Se requiere al menos un --verification."
  local dep
  for dep in "${dependencies[@]:-}"; do
    [ -n "$dep" ] || continue
    task_exists "$path" "$dep" || err "No existe la dependencia $dep."
  done

  local task_id now; task_id="$(next_task_id "$path")"; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  set_task "$path" "$task_id" "$source_node_id" "$(sanitize "$title")" "$(sanitize "$description")" READY "" "$now" "$now"
  local s; for s in "${steps[@]}"; do [ -n "$s" ] && append_line "$path" "STEP${TAB}${task_id}${TAB}$(sanitize "$s")"; done
  local v; for v in "${verifications[@]}"; do [ -n "$v" ] && append_line "$path" "VERIFY${TAB}${task_id}${TAB}$(sanitize "$v")"; done
  for dep in "${dependencies[@]:-}"; do [ -n "$dep" ] && append_line "$path" "DEP${TAB}${task_id}${TAB}${dep}"; done
  touch_updated_at "$path"
  require_valid "$path"
  echo "$ticket: task-add $task_id (source=$source_node_id)"
}

cmd_item_complete() {
  local ticket="$1"; shift
  local source_node_id=""
  while [ $# -gt 0 ]; do case "$1" in --source-node-id) source_node_id="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  ! is_planned "$path" "$source_node_id" || err "El work item $source_node_id ya está completo."
  local found=0 blocked=()
  local task_id
  while IFS= read -r task_id; do
    [ -n "$task_id" ] || continue
    [ "$(task_field "$path" "$task_id" source_node_id)" = "$source_node_id" ] || continue
    found=1
    [ "$(task_field "$path" "$task_id" status)" = "READY" ] || blocked+=("$task_id")
  done <<< "$(task_ids "$path")"
  [ "$found" -eq 1 ] || err "El work item requiere al menos una tarea persistida."
  [ ${#blocked[@]} -eq 0 ] || err "No se puede cerrar el work item; tareas no listas: ${blocked[*]}."
  append_line "$path" "PLANNED${TAB}${source_node_id}"
  touch_updated_at "$path"
  require_valid "$path"
  echo "$ticket: item-complete $source_node_id"
}

cmd_complete() {
  local ticket="$1"; shift
  local evidence=""
  while [ $# -gt 0 ]; do case "$1" in --evidence) evidence="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  [ -n "$evidence" ] || err "Se requiere evidencia no vacía."
  local pending; pending="$(comm -23 <(work_item_ids "$path" | sort -u) <(planned_items "$path" | sort -u) 2>/dev/null | grep -c . || true)"
  [ "$pending" -eq 0 ] || err "No se puede completar el plan mientras haya work items pendientes."
  local task_id
  while IFS= read -r task_id; do
    [ -n "$task_id" ] || continue
    [ "$(task_field "$path" "$task_id" status)" = "READY" ] || err "No se puede completar el plan con tareas bloqueadas."
  done <<< "$(task_ids "$path")"
  meta_set "$path" status COMPLETE
  meta_set "$path" completion_evidence "$(sanitize "$evidence")"
  touch_updated_at "$path"
  require_valid "$path"
  echo "$ticket: complete status=COMPLETE"
}

cmd_export() {
  local path; path="$(require_state "$1")"
  require_valid "$path"
  echo "objective: $(meta_get "$path" objective)"
  echo "tasks:"
  local task_id
  while IFS= read -r task_id; do
    [ -n "$task_id" ] || continue
    echo "  - $task_id: $(task_field "$path" "$task_id" title)"
  done <<< "$(task_ids "$path")"
}

cmd_export_file() {
  local ticket="$1"; shift
  local output=""
  while [ $# -gt 0 ]; do case "$1" in --output) output="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  [ -n "$output" ] || err "--output es obligatorio."
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  [ "$(meta_get "$path" status)" = "COMPLETE" ] || err "Solo se puede exportar un plan COMPLETE."

  mkdir -p "$(dirname "$output")"
  local tmp; tmp="$(mktemp)"
  local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  {
    printf 'META%sschema_version%s1\n' "$TAB" "$TAB"
    printf 'META%skind%simplementation-plan\n' "$TAB" "$TAB"
    printf 'META%sticket%s%s\n' "$TAB" "$TAB" "$ticket"
    printf 'META%sstatus%sREADY\n' "$TAB" "$TAB"
    printf 'META%sexecution_status%sPENDING\n' "$TAB" "$TAB"
    printf 'META%sgenerated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'META%supdated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'META%sobjective%s%s\n' "$TAB" "$TAB" "$(meta_get "$path" objective)"
    local order=0 task_id
    while IFS= read -r task_id; do
      [ -n "$task_id" ] || continue
      order=$((order + 1))
      printf '%s\n' "TASK${TAB}${task_id}${TAB}${order}${TAB}$(task_field "$path" "$task_id" source_node_id)${TAB}$(task_field "$path" "$task_id" title)${TAB}$(task_field "$path" "$task_id" description)${TAB}PENDING${TAB}${TAB}${TAB}${TAB}"
      task_steps "$path" "$task_id" | while IFS= read -r s; do printf 'STEP%s%s%s%s\n' "$TAB" "$task_id" "$TAB" "$s"; done
      task_verifications "$path" "$task_id" | while IFS= read -r v; do printf 'VERIFY%s%s%s%s\n' "$TAB" "$task_id" "$TAB" "$v"; done
      task_dependencies "$path" "$task_id" | while IFS= read -r d; do printf 'DEP%s%s%s%s\n' "$TAB" "$task_id" "$TAB" "$d"; done
    done <<< "$(task_ids "$path")"
  } > "$tmp"
  mv "$tmp" "$output"
  local count; count="$(task_ids "$path" | grep -c . || true)"
  echo "$ticket: export-file plan_file=$output task_count=$count"
}

cmd_task_block() {
  local ticket="$1"; shift
  local task_id="" reason=""
  while [ $# -gt 0 ]; do case "$1" in --task-id) task_id="$2"; shift 2 ;; --reason) reason="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  task_exists "$path" "$task_id" || err "No existe la tarea $task_id."
  [ -n "$reason" ] || err "Se requiere un motivo no vacío."
  local source title desc created; source="$(task_field "$path" "$task_id" source_node_id)"; title="$(task_field "$path" "$task_id" title)"
  desc="$(task_field "$path" "$task_id" description)"; created="$(task_field "$path" "$task_id" created_at)"
  set_task "$path" "$task_id" "$source" "$title" "$desc" BLOCKED "$(sanitize "$reason")" "$created" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  meta_set "$path" status BLOCKED
  touch_updated_at "$path"
  require_valid "$path"
  echo "$ticket: task-block $task_id"
}

cmd_task_unblock() {
  local ticket="$1"; shift
  local task_id="" resolution=""
  while [ $# -gt 0 ]; do case "$1" in --task-id) task_id="$2"; shift 2 ;; --resolution) resolution="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  local path; path="$(require_state "$ticket")"
  require_valid "$path"
  task_exists "$path" "$task_id" || err "No existe la tarea $task_id."
  [ "$(task_field "$path" "$task_id" status)" = "BLOCKED" ] || err "La tarea $task_id no está BLOCKED."
  [ -n "$resolution" ] || err "Se requiere una resolución no vacía."
  local source title desc created; source="$(task_field "$path" "$task_id" source_node_id)"; title="$(task_field "$path" "$task_id" title)"
  desc="$(task_field "$path" "$task_id" description)"; created="$(task_field "$path" "$task_id" created_at)"
  set_task "$path" "$task_id" "$source" "$title" "$desc" READY "" "$created" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  meta_set "$path" status IN_PROGRESS
  touch_updated_at "$path"
  require_valid "$path"
  echo "$ticket: task-unblock $task_id (resolución: $resolution)"
}

usage() {
  cat >&2 <<'EOF'
Uso: plan_state.sh <comando> <ticket> ...
  init <ticket>
  validate <ticket>
  next <ticket>
  task-add <ticket> --source-node-id <id> --title <t> --description <t> --implementation-step <t> [...] --verification <t> [...] [--depends-on <task-id> ...]
  item-complete <ticket> --source-node-id <id>
  complete <ticket> --evidence <t>
  export <ticket>
  export-file <ticket> --output <path>
  task-block <ticket> --task-id <id> --reason <t>
  task-unblock <ticket> --task-id <id> --resolution <t>
EOF
  exit 2
}

main() {
  local command="${1:-}"; [ -n "$command" ] || usage; shift
  [ $# -ge 1 ] || usage
  local ticket; ticket="$(normalize_issue_id "$1")"; shift
  case "$command" in
    init) cmd_init "$ticket" ;;
    validate) cmd_validate "$ticket" ;;
    next) cmd_next "$ticket" ;;
    task-add) cmd_task_add "$ticket" "$@" ;;
    item-complete) cmd_item_complete "$ticket" "$@" ;;
    complete) cmd_complete "$ticket" "$@" ;;
    export) cmd_export "$ticket" ;;
    export-file) cmd_export_file "$ticket" "$@" ;;
    task-block) cmd_task_block "$ticket" "$@" ;;
    task-unblock) cmd_task_unblock "$ticket" "$@" ;;
    *) usage ;;
  esac
}

main "$@"
