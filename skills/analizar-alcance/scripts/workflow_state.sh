#!/usr/bin/env bash
# Registro secuencial y fail-closed para el flujo de /cocinar y /analizar-alcance.
# Sin dependencias externas (sin Python, sin jq): estado en texto plano,
# un archivo por ticket, líneas con tag de tipo separadas por TAB.
set -euo pipefail

TAB=$'\t'
PHASES=(ticket analizar-alcance entrevistar guia-proyecto plan aprobacion branch implementacion pr)
SCOPE_STATUSES=(PENDING IN_PROGRESS BLOCKED DONE)
SCOPE_VERDICTS=(APTO_PARA_IMPLEMENTAR REQUIERE_DIVISION BLOQUEADO)

err() { echo "ERROR: $*" >&2; exit 1; }

in_list() {
  local needle="$1"; shift
  for x in "$@"; do [ "$x" = "$needle" ] && return 0; done
  return 1
}

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
  case "$id" in
    *[[:space:]]*|*/*|*'\'*) err "ID de issue inválido: '$raw'. No puede tener espacios ni '/'." ;;
  esac
  printf '%s' "$id"
}

slug_for_filename() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '-' | tr 'A-Z' 'a-z' | sed -e 's/^-*//' -e 's/-*$//'
}

state_path() {
  local slug; slug="$(slug_for_filename "$1")"
  [ -n "$slug" ] && slug="$slug" || slug="issue"
  printf '%s/cocinar-%s-%s-state.txt' "${TMPDIR:-/tmp}" "$slug" "$(project_hash)"
}

verdict_path() {
  local sp; sp="$(state_path "$1")"
  printf '%s/%s-veredicto.md' "$(dirname "$sp")" "$(basename "$sp" | sed -E 's/-state\.txt$//')"
}

counter_path() { printf '%s/dotskills-task-counter-%s.txt' "${TMPDIR:-/tmp}" "$(project_hash)"; }

PLACEHOLDER_RE='\{\{[A-Z0-9_]+\}\}'

cmd_next_id() {
  local path next_n=1
  path="$(counter_path)"
  mkdir -p "$(dirname "$path")"
  [ -f "$path" ] && next_n="$(cat "$path")"
  [ -n "$next_n" ] || next_n=1
  printf 'TASK-%03d\n' "$next_n"
  echo $((next_n + 1)) > "$path"
}

cmd_verdict_path() { verdict_path "$1"; }

cmd_check_verdict() {
  local path; path="$(verdict_path "$1")"
  [ -f "$path" ] || err "No existe el veredicto en $path. Escribilo a partir de veredicto-template.md antes de validar."
  local leftovers; leftovers="$(grep -oE "$PLACEHOLDER_RE" "$path" | sort -u || true)"
  [ -z "$leftovers" ] || err "Quedan placeholders sin completar en el veredicto: $(echo "$leftovers" | tr '\n' ' ')"
  echo "$1: veredicto OK ($path)"
}

# --- primitivas de lectura/escritura sobre el archivo de estado --------

require_state() {
  local ticket="$1" path; path="$(state_path "$ticket")"
  [ -f "$path" ] || err "No existe registro para $ticket. Ejecuta primero: workflow_state.sh init $ticket"
  printf '%s' "$path"
}

# Reemplaza la primera línea cuyo prefijo (con TABs literales) coincide con
# $2; si ninguna coincide, agrega $3 al final. Usado para registros únicos
# (META, CONTEXT por campo, PHASE por nombre, SCOPEMETA por clave).
upsert_line() {
  local path="$1" prefix="$2" new_line="$3" tmp found=0
  tmp="$(mktemp)"
  if [ -f "$path" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        "$prefix"*) printf '%s\n' "$new_line" >> "$tmp"; found=1 ;;
        *) printf '%s\n' "$line" >> "$tmp" ;;
      esac
    done < "$path"
  fi
  [ "$found" -eq 1 ] || printf '%s\n' "$new_line" >> "$tmp"
  mv "$tmp" "$path"
}

append_line() { printf '%s\n' "$2" >> "$1"; }

get_field() {
  # $1 path, $2 prefix (con TABs), $3 número de campo (awk, 1-indexado)
  local path="$1" prefix="$2" field="$3"
  [ -f "$path" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$prefix"*) printf '%s' "$line" | awk -F'\t' -v f="$field" '{print $f}'; return 0 ;;
    esac
  done < "$path"
}

line_exists() {
  local path="$1" prefix="$2"
  [ -f "$path" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$prefix"*) return 0 ;; esac
  done < "$path"
  return 1
}

# --- meta / ticket_context / phases -------------------------------------

new_state() {
  local ticket="$1" path="$2" now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  {
    printf 'META%sticket%s%s\n' "$TAB" "$TAB" "$ticket"
    printf 'META%sproject%s%s\n' "$TAB" "$TAB" "$(pwd)"
    printf 'META%screated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'META%supdated_at%s%s\n' "$TAB" "$TAB" "$now"
    printf 'CONTEXT%sid%s%s%s%s%s1\n' "$TAB" "$TAB" "$ticket" "$TAB" "argument" "$TAB"
    printf 'CONTEXT%stitle%s%s%s%s%s0\n' "$TAB" "$TAB" "" "$TAB" "" "$TAB"
    printf 'CONTEXT%sdescription%s%s%s%s%s0\n' "$TAB" "$TAB" "" "$TAB" "" "$TAB"
    for phase in "${PHASES[@]}"; do
      printf 'PHASE%s%s%sPENDING%s%s%s%s\n' "$TAB" "$phase" "$TAB" "$TAB" "$TAB" "$TAB" ""
    done
    printf 'SCOPEMETA%sstatus%sPENDING\n' "$TAB" "$TAB"
    printf 'SCOPEMETA%sroot%s%s\n' "$TAB" "$TAB" "$ticket"
    printf 'SCOPEMETA%sobjective%s\n' "$TAB" "$TAB"
    printf 'SCOPEMETA%supdated_at%s\n' "$TAB" "$TAB"
  } > "$path"
}

touch_updated_at() {
  local path="$1" now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  upsert_line "$path" "META${TAB}updated_at${TAB}" "META${TAB}updated_at${TAB}${now}"
}

ticket_of() { get_field "$1" "META${TAB}ticket${TAB}" 3; }
project_of() { get_field "$1" "META${TAB}project${TAB}" 3; }

check_state_owner() {
  local path="$1" ticket="$2"
  [ "$(ticket_of "$path")" = "$ticket" ] || err "El registro no corresponde al ticket solicitado."
  [ "$(project_of "$path")" = "$(pwd)" ] || err "El registro pertenece a otro proyecto."
}

get_context() {
  # $1 path $2 field(id|title|description) -> imprime value<TAB>source<TAB>confirmed
  local path="$1" field="$2" line
  line="$(get_field "$path" "CONTEXT${TAB}${field}${TAB}" 0 2>/dev/null || true)"
  awk -F'\t' -v pre="CONTEXT${TAB}${field}${TAB}" 'index($0, pre)==1 {print $3"\t"$4"\t"$5; found=1} END{if(!found) print "\t\t0"}' "$path"
}

context_complete() {
  local path="$1" field value confirmed
  for field in id title description; do
    IFS=$'\t' read -r value _source confirmed < <(get_context "$path" "$field")
    [ "$confirmed" = "1" ] || return 1
    [ -n "$value" ] || return 1
  done
  return 0
}

get_phase() {
  # $1 path $2 phase -> status<TAB>evidence<TAB>reason<TAB>updated_at
  awk -F'\t' -v ph="$2" -v pre="PHASE" '$1==pre && $2==ph {print $3"\t"$4"\t"$5"\t"$6; found=1} END{if(!found) exit 1}' "$1"
}

phase_status() { get_phase "$1" "$2" | cut -f1; }

previous_done() {
  local path="$1" target="$2" phase status
  for phase in "${PHASES[@]}"; do
    [ "$phase" = "$target" ] && return 0
    status="$(phase_status "$path" "$phase")"
    [ "$status" = "DONE" ] || return 1
  done
}

any_in_progress_other_than() {
  local path="$1" except="$2" phase status
  for phase in "${PHASES[@]}"; do
    [ "$phase" = "$except" ] && continue
    status="$(phase_status "$path" "$phase")"
    [ "$status" = "IN_PROGRESS" ] && { echo "$phase"; return 0; }
  done
  return 1
}

# --- scope: items / edges / criteria ------------------------------------

scopemeta_get() { get_field "$1" "SCOPEMETA${TAB}$2${TAB}" 3; }
scopemeta_set() { upsert_line "$1" "SCOPEMETA${TAB}$2${TAB}" "SCOPEMETA${TAB}$2${TAB}$3"; }

item_line() { awk -F'\t' -v id="$2" '$1=="ITEM" && $2==id' "$1"; }
item_exists() { [ -n "$(item_line "$1" "$2")" ]; }

item_field() {
  # $1 path $2 id $3 field(title|status|verdict|parent)
  local idx
  case "$3" in title) idx=3 ;; status) idx=4 ;; verdict) idx=5 ;; parent) idx=6 ;; *) err "campo desconocido: $3" ;; esac
  item_line "$1" "$2" | awk -F'\t' -v i="$idx" '{print $i}'
}

all_item_ids() { awk -F'\t' '$1=="ITEM"{print $2}' "$1"; }

item_children() { awk -F'\t' -v p="$2" '$1=="EDGE" && $2==p {print $3}' "$1"; }

item_criteria() { awk -F'\t' -v id="$2" '$1=="CRITERION" && $2==id {print $3}' "$1"; }
item_criteria_count() { item_criteria "$1" "$2" | grep -c . || true; }

set_item() {
  # upsert de una línea ITEM completa
  local path="$1" id="$2" title="$3" status="$4" verdict="$5" parent="$6"
  local new_line="ITEM${TAB}${id}${TAB}${title}${TAB}${status}${TAB}${verdict}${TAB}${parent}"
  upsert_line "$path" "ITEM${TAB}${id}${TAB}" "$new_line"
}

set_criteria() {
  # reemplaza todas las CRITERION de un item por las pasadas en $3..$n
  local path="$1" id="$2"; shift 2
  local tmp; tmp="$(mktemp)"
  awk -F'\t' -v id="$id" '!($1=="CRITERION" && $2==id)' "$path" > "$tmp"
  mv "$tmp" "$path"
  local c
  for c in "$@"; do
    [ -n "$c" ] && append_line "$path" "CRITERION${TAB}${id}${TAB}$(sanitize "$c")"
  done
}

# Valida el árbol de scope completo. Imprime errores (uno por línea) y
# retorna 1 si hay alguno.
scope_validate() {
  local path="$1" errors=0
  local root status objective
  root="$(scopemeta_get "$path" root)"
  status="$(scopemeta_get "$path" status)"
  objective="$(scopemeta_get "$path" objective)"

  local ids; ids="$(all_item_ids "$path")"
  if [ -n "$ids" ] && ! printf '%s\n' "$ids" | grep -qx "$root"; then
    echo "scope.items debe contener el nodo raíz."; errors=1
  fi
  if [ "$status" = "CONFIRMED" ] && [ -z "$objective" ]; then
    echo "scope.objective es obligatorio para CONFIRMED."; errors=1
  fi

  local id title item_status verdict parent children_count crit_count
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    title="$(item_field "$path" "$id" title)"
    item_status="$(item_field "$path" "$id" status)"
    verdict="$(item_field "$path" "$id" verdict)"
    parent="$(item_field "$path" "$id" parent)"

    [ -n "$title" ] || { echo "El nodo $id requiere un título no vacío."; errors=1; }
    in_list "$item_status" "${SCOPE_STATUSES[@]}" || { echo "El nodo $id tiene un status inválido."; errors=1; }
    in_list "$verdict" "${SCOPE_VERDICTS[@]}" || { echo "El nodo $id tiene un verdict inválido."; errors=1; }
    if [ "$parent" != "-" ] && ! item_exists "$path" "$parent"; then
      echo "El padre del nodo $id no existe."; errors=1
    fi
    children_count="$(item_children "$path" "$id" | grep -c . || true)"
    if [ "$item_status" = "DONE" ] && [ "$verdict" != "APTO_PARA_IMPLEMENTAR" ] && [ "$verdict" != "REQUIERE_DIVISION" ]; then
      echo "El nodo $id solo puede estar DONE si es apto o si su división fue resuelta."; errors=1
    fi
    if [ "$verdict" = "REQUIERE_DIVISION" ] && [ "$children_count" -eq 0 ]; then
      echo "El nodo $id requiere hijos si su veredicto es REQUIERE_DIVISION."; errors=1
    fi
    if [ "$item_status" = "BLOCKED" ] && [ "$verdict" != "BLOQUEADO" ]; then
      echo "El nodo $id solo puede estar BLOCKED si está bloqueado."; errors=1
    fi
    if [ "$item_status" = "BLOCKED" ] && [ "$children_count" -gt 0 ]; then
      echo "El nodo $id no puede tener hijos mientras está BLOCKED."; errors=1
    fi
    if [ "$verdict" = "APTO_PARA_IMPLEMENTAR" ]; then
      crit_count="$(item_criteria_count "$path" "$id")"
      [ "$crit_count" -gt 0 ] || { echo "El nodo $id requiere acceptance_criteria como lista no vacía."; errors=1; }
    fi
  done <<< "$ids"

  # cada EDGE debe apuntar a un hijo existente cuyo parent coincida
  while IFS=$'\t' read -r _tag parent_id child_id; do
    [ -n "${child_id:-}" ] || continue
    if ! item_exists "$path" "$child_id"; then
      echo "El hijo $child_id del nodo $parent_id no existe."; errors=1
    elif [ "$(item_field "$path" "$child_id" parent)" != "$parent_id" ]; then
      echo "El padre del hijo $child_id no coincide con $parent_id."; errors=1
    fi
  done < <(awk -F'\t' '$1=="EDGE"' "$path")

  [ "$errors" -eq 0 ]
}

scope_all_done() {
  local path="$1" id status
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    status="$(item_field "$path" "$id" status)"
    [ "$status" = "DONE" ] || return 1
  done <<< "$(all_item_ids "$path")"
  return 0
}

scope_complete() {
  local path="$1"
  [ -n "$(all_item_ids "$path")" ] || return 1
  scope_validate "$path" >/dev/null || return 1
  [ "$(scopemeta_get "$path" status)" = "CONFIRMED" ] || return 1
  scope_all_done "$path"
}

# --- validación global ----------------------------------------------------

validate_state() {
  local path="$1" errors=0 active=0
  while IFS= read -r e; do [ -n "$e" ] && { echo "$e"; errors=1; }; done < <(scope_validate "$path" || true)

  local phase status evidence reason
  for phase in "${PHASES[@]}"; do
    IFS=$'\t' read -r status evidence reason _updated < <(get_phase "$path" "$phase")
    case "$status" in PENDING|IN_PROGRESS|BLOCKED|DONE) ;; *) echo "La fase $phase tiene status inválido."; errors=1 ;; esac
    [ "$status" = "IN_PROGRESS" ] && active=$((active + 1))
    if [ "$status" = "DONE" ] && [ -z "$evidence" ]; then echo "La fase $phase está DONE sin evidencia."; errors=1; fi
    if [ "$status" = "BLOCKED" ] && [ -z "$reason" ]; then echo "La fase $phase está BLOCKED sin motivo."; errors=1; fi
  done
  [ "$active" -le 1 ] || { echo "Existe más de una fase IN_PROGRESS."; errors=1; }
  [ "$errors" -eq 0 ]
}

require_valid() {
  local path="$1" out
  out="$(validate_state "$path" || true)"
  [ -z "$out" ] || err "Estado inválido: $(echo "$out" | tr '\n' '|')"
}

# --- comandos --------------------------------------------------------------

cmd_init() {
  local ticket="$1" path; path="$(state_path "$ticket")"
  if [ -f "$path" ]; then
    check_state_owner "$path" "$ticket"
    echo "$ticket: registro existente en $path"
  else
    new_state "$ticket" "$path"
    echo "$ticket: registro creado en $path"
  fi
  cmd_show "$ticket" --compact
}

cmd_show() {
  local ticket="$1" compact="${2:-}" path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"
  local ctx_ok="INCOMPLETE"; context_complete "$path" && ctx_ok="COMPLETE"
  local scope_ok; if scope_complete "$path" 2>/dev/null; then scope_ok="COMPLETE"; else scope_ok="$(scopemeta_get "$path" status)"; fi
  if [ "$compact" = "--compact" ]; then
    local done_count=0 parts=()
    for phase in "${PHASES[@]}"; do
      [ "$(phase_status "$path" "$phase")" = "DONE" ] && done_count=$((done_count + 1))
    done
    echo "$ticket: DONE $done_count/${#PHASES[@]} | ticket_context=$ctx_ok | scope=$scope_ok | state=$path"
  else
    echo "Ticket: $ticket"
    echo "Registro: $path"
    echo "ticket_context: $ctx_ok"
    echo "scope_analysis: $scope_ok"
    for phase in "${PHASES[@]}"; do
      IFS=$'\t' read -r status evidence reason _updated < <(get_phase "$path" "$phase")
      detail="${evidence:-$reason}"
      [ -n "$detail" ] && detail=" — $detail" || detail=""
      printf '[%-11s] %s%s\n' "$status" "$phase" "$detail"
    done
  fi
}

cmd_start() {
  local ticket="$1" phase="$2" path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_valid "$path"
  if { [ "$phase" = "analizar-alcance" ] || [ "$phase" = "entrevistar" ]; } && ! context_complete "$path"; then
    err "No se puede iniciar '$phase': ticket_context está incompleto."
  fi
  if [ "$phase" = "entrevistar" ] && ! scope_complete "$path" 2>/dev/null; then
    err "No se puede iniciar 'entrevistar': scope_analysis no está confirmado."
  fi
  previous_done "$path" "$phase" || err "No se puede iniciar '$phase': hay una fase anterior sin DONE."
  local other; other="$(any_in_progress_other_than "$path" "$phase" || true)"
  [ -z "$other" ] || err "Ya existe una fase IN_PROGRESS: $other"
  [ "$(phase_status "$path" "$phase")" != "DONE" ] || err "La fase '$phase' ya está DONE."
  upsert_line "$path" "PHASE${TAB}${phase}${TAB}" "PHASE${TAB}${phase}${TAB}IN_PROGRESS${TAB}${TAB}"
  touch_updated_at "$path"
  echo "$ticket: $phase=IN_PROGRESS"
}

cmd_done() {
  local ticket="$1" phase="$2"; shift 2
  local evidence="" jira_read=0 user_approved=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --evidence) evidence="$2"; shift 2 ;;
      --jira-read) jira_read=1; shift ;;
      --user-approved) user_approved=1; shift ;;
      *) err "Argumento desconocido: $1" ;;
    esac
  done
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_valid "$path"
  [ "$(phase_status "$path" "$phase")" = "IN_PROGRESS" ] || err "La fase '$phase' debe estar IN_PROGRESS antes de marcarla DONE."
  previous_done "$path" "$phase" || err "No se puede terminar '$phase': hay una fase anterior sin DONE."
  [ -n "$evidence" ] || err "Se requiere evidencia no vacía."

  if [ "$phase" = "ticket" ]; then
    context_complete "$path" || err "La fase 'ticket' requiere ticket_context completo."
    local id_source; id_source="$(get_context "$path" id | cut -f2)"
    if [ "$jira_read" -eq 1 ] && [ "$id_source" != "jira" ]; then err "--jira-read requiere ticket_context con origen 'jira'."; fi
    if [ "$jira_read" -eq 0 ] && [ "$id_source" != "user" ]; then err "Sin --jira-read, ticket_context debe tener origen 'user'."; fi
  fi
  if [ "$phase" = "aprobacion" ] && [ "$user_approved" -eq 0 ]; then
    err "La fase 'aprobacion' requiere --user-approved tras un OK explícito."
  fi
  if [ "$phase" = "analizar-alcance" ] && ! scope_complete "$path" 2>/dev/null; then
    err "La fase 'analizar-alcance' requiere scope_analysis confirmado y todos los nodos DONE."
  fi

  upsert_line "$path" "PHASE${TAB}${phase}${TAB}" "PHASE${TAB}${phase}${TAB}DONE${TAB}$(sanitize "$evidence")${TAB}"
  touch_updated_at "$path"
  echo "$ticket: $phase=DONE"
}

cmd_context() {
  local ticket="$1"; shift
  local id="" title="" description="" source=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --id) id="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --source) source="$2"; shift 2 ;;
      *) err "Argumento desconocido: $1" ;;
    esac
  done
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"
  [ "$(phase_status "$path" ticket)" = "IN_PROGRESS" ] || err "ticket_context solo puede completarse mientras la fase 'ticket' está IN_PROGRESS."
  local normalized; normalized="$(normalize_issue_id "$id")"
  [ "$normalized" = "$ticket" ] || err "El ID del ticket context ($normalized) no coincide con $ticket."
  [ -n "$title" ] && [ -n "$description" ] || err "ticket_context requiere título y descripción no vacíos."
  case "$source" in jira|user) ;; *) err "source debe ser 'jira' o 'user'." ;; esac

  upsert_line "$path" "CONTEXT${TAB}id${TAB}" "CONTEXT${TAB}id${TAB}${normalized}${TAB}${source}${TAB}1"
  upsert_line "$path" "CONTEXT${TAB}title${TAB}" "CONTEXT${TAB}title${TAB}$(sanitize "$title")${TAB}${source}${TAB}1"
  upsert_line "$path" "CONTEXT${TAB}description${TAB}" "CONTEXT${TAB}description${TAB}$(sanitize "$description")${TAB}${source}${TAB}1"
  touch_updated_at "$path"
  echo "$ticket: ticket_context=COMPLETE source=$source"
}

require_scope_in_progress() {
  local path="$1"
  [ "$(phase_status "$path" analizar-alcance)" = "IN_PROGRESS" ] || err "scope_analysis solo puede actualizarse mientras analizar-alcance está IN_PROGRESS."
}

cmd_scope_set_objective() {
  local ticket="$1"; shift
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_scope_in_progress "$path"
  local objective="$*"
  [ -n "$objective" ] || err "El objetivo no puede estar vacío."
  scopemeta_set "$path" objective "$(sanitize "$objective")"
  touch_updated_at "$path"
  echo "$ticket: objective actualizado"
}

cmd_scope_add_item() {
  local ticket="$1" id="$2" parent="$3" status="$4" verdict="$5"; shift 5
  local title="$*"
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_scope_in_progress "$path"
  ! item_exists "$path" "$id" || err "El nodo $id ya existe. Usá scope-set-item para modificarlo."
  in_list "$status" "${SCOPE_STATUSES[@]}" || err "status inválido: $status"
  in_list "$verdict" "${SCOPE_VERDICTS[@]}" || err "verdict inválido: $verdict"
  [ -n "$title" ] || err "El nodo requiere título."
  if [ "$parent" != "-" ]; then
    item_exists "$path" "$parent" || err "No existe el nodo padre $parent."
    append_line "$path" "EDGE${TAB}${parent}${TAB}${id}"
  fi
  set_item "$path" "$id" "$(sanitize "$title")" "$status" "$verdict" "$parent"
  touch_updated_at "$path"
  echo "$ticket: item $id agregado (parent=$parent, status=$status, verdict=$verdict)"
}

cmd_scope_set_item() {
  local ticket="$1" id="$2"; shift 2
  local status="" verdict=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) status="$2"; shift 2 ;;
      --verdict) verdict="$2"; shift 2 ;;
      *) err "Argumento desconocido: $1" ;;
    esac
  done
  [ -n "$status" ] || [ -n "$verdict" ] || err "Indicá --status y/o --verdict."
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_scope_in_progress "$path"
  item_exists "$path" "$id" || err "No existe el nodo $id."
  local title parent cur_status cur_verdict
  title="$(item_field "$path" "$id" title)"; parent="$(item_field "$path" "$id" parent)"
  cur_status="$(item_field "$path" "$id" status)"; cur_verdict="$(item_field "$path" "$id" verdict)"
  [ -n "$status" ] && { in_list "$status" "${SCOPE_STATUSES[@]}" || err "status inválido: $status"; cur_status="$status"; }
  [ -n "$verdict" ] && { in_list "$verdict" "${SCOPE_VERDICTS[@]}" || err "verdict inválido: $verdict"; cur_verdict="$verdict"; }
  set_item "$path" "$id" "$title" "$cur_status" "$cur_verdict" "$parent"
  touch_updated_at "$path"
  echo "$ticket: item $id -> status=$cur_status verdict=$cur_verdict"
}

cmd_scope_set_criteria() {
  local ticket="$1" id="$2"; shift 2
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_scope_in_progress "$path"
  item_exists "$path" "$id" || err "No existe el nodo $id."
  set_criteria "$path" "$id" "$@"
  touch_updated_at "$path"
  echo "$ticket: criterios de $id actualizados ($# provistos)"
}

cmd_scope_confirm() {
  local ticket="$1" path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_scope_in_progress "$path"
  local out; out="$(scope_validate "$path" || true)"
  [ -z "$out" ] || err "scope_analysis inválido: $(echo "$out" | tr '\n' '|')"
  scope_all_done "$path" || err "scope_analysis solo puede CONFIRMED con todos los nodos DONE."
  [ -n "$(scopemeta_get "$path" objective)" ] || err "scope_analysis.objective es obligatorio."
  scopemeta_set "$path" status CONFIRMED
  touch_updated_at "$path"
  echo "$ticket: scope_analysis=CONFIRMED"
}

cmd_validate() {
  local ticket="$1" path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"; require_valid "$path"
  echo "$ticket: VALID state=$path"
}

cmd_block() {
  local ticket="$1" phase="$2"; shift 2
  local reason=""
  while [ $# -gt 0 ]; do case "$1" in --reason) reason="$2"; shift 2 ;; *) err "Argumento desconocido: $1" ;; esac; done
  local path; path="$(require_state "$ticket")"
  check_state_owner "$path" "$ticket"
  [ "$(phase_status "$path" "$phase")" != "DONE" ] || err "No se puede bloquear '$phase': ya está DONE."
  [ -n "$reason" ] || err "Se requiere un motivo no vacío."
  upsert_line "$path" "PHASE${TAB}${phase}${TAB}" "PHASE${TAB}${phase}${TAB}BLOCKED${TAB}${TAB}$(sanitize "$reason")"
  touch_updated_at "$path"
  echo "$ticket: $phase=BLOCKED — $reason"
}

usage() {
  cat >&2 <<'EOF'
Uso: workflow_state.sh <comando> ...
  init <ticket>
  show <ticket> [--compact]
  start <ticket> <phase>
  done <ticket> <phase> --evidence <t> [--jira-read] [--user-approved]
  context <ticket> --id <id> --title <t> --description <t> --source <jira|user>
  scope-set-objective <ticket> <objetivo...>
  scope-add-item <ticket> <id> <parent|-> <status> <verdict> <título...>
  scope-set-item <ticket> <id> [--status <s>] [--verdict <v>]
  scope-set-criteria <ticket> <id> [criterio...]
  scope-confirm <ticket>
  validate <ticket>
  block <ticket> <phase> --reason <t>
  next-id
  verdict-path <ticket>
  check-verdict <ticket>
EOF
  exit 2
}

main() {
  local command="${1:-}"
  [ -n "$command" ] || usage
  shift
  if [ "$command" = "next-id" ]; then cmd_next_id; return 0; fi

  [ $# -ge 1 ] || usage
  local ticket; ticket="$(normalize_issue_id "$1")"; shift

  case "$command" in
    init) cmd_init "$ticket" ;;
    show) cmd_show "$ticket" "${1:-}" ;;
    start) [ $# -eq 1 ] || usage; cmd_start "$ticket" "$1" ;;
    done) [ $# -ge 1 ] || usage; local phase="$1"; shift; cmd_done "$ticket" "$phase" "$@" ;;
    context) cmd_context "$ticket" "$@" ;;
    scope-set-objective) cmd_scope_set_objective "$ticket" "$@" ;;
    scope-add-item) [ $# -ge 5 ] || usage; cmd_scope_add_item "$ticket" "$@" ;;
    scope-set-item) [ $# -ge 2 ] || usage; local id="$1"; shift; cmd_scope_set_item "$ticket" "$id" "$@" ;;
    scope-set-criteria) [ $# -ge 1 ] || usage; local id="$1"; shift; cmd_scope_set_criteria "$ticket" "$id" "$@" ;;
    scope-confirm) cmd_scope_confirm "$ticket" ;;
    validate) cmd_validate "$ticket" ;;
    block) [ $# -ge 1 ] || usage; local phase="$1"; shift; cmd_block "$ticket" "$phase" "$@" ;;
    verdict-path) cmd_verdict_path "$ticket" ;;
    check-verdict) cmd_check_verdict "$ticket" ;;
    *) usage ;;
  esac
}

main "$@"
