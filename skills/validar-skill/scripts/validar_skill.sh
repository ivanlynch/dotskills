#!/usr/bin/env bash
# Registro determinístico y fail-closed para el checklist de /validar-skill.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKLIST_FILE="$SCRIPT_DIR/../validaciones.md"

err() {
  echo "ERROR: $*" >&2
  exit 1
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | cut -d' ' -f1
  else
    err "Se necesita sha256sum o shasum para calcular el hash del skill."
  fi
}

project_hash() {
  pwd | sha256_of | cut -c1-12
}

target_dir() {
  local target="$1"
  local dir="./skills/$target"
  [ -f "$dir/SKILL.md" ] || err "No existe skills/$target/SKILL.md (ejecutá esto desde la raíz del repo)."
  echo "$dir"
}

compute_hash() {
  local dir="$1"
  {
    cat "$CHECKLIST_FILE"
    cat "$dir/SKILL.md"
    for sub in scripts references assets; do
      if [ -d "$dir/$sub" ]; then
        find "$dir/$sub" -type f | LC_ALL=C sort | while IFS= read -r f; do cat "$f"; done
      fi
    done
  } | sha256_of
}

state_path() {
  local target="$1"
  printf '%s/validar-skill-%s-%s-state.txt' "${TMPDIR:-/tmp}" "$target" "$(project_hash)"
}

checklist_ids() {
  grep -oE '^\| `[a-z0-9-]+`' "$CHECKLIST_FILE" | sed -E 's/^\| `([a-z0-9-]+)`/\1/'
}

require_state() {
  local target="$1"
  local path
  path="$(state_path "$target")"
  [ -f "$path" ] || err "No hay estado para '$target'. Ejecutá primero: validar_skill.sh init $target"
  echo "$path"
}

read_hash() {
  awk -F'\t' '$1 == "HASH" { print $2; exit }' "$1"
}

print_status() {
  local path="$1"
  local done=0 na=0 pending=0 total=0
  echo "ID	ESTADO"
  while IFS=$'\t' read -r id status _nota; do
    [ "$id" = "HASH" ] && continue
    total=$((total + 1))
    case "$status" in
      DONE) done=$((done + 1)) ;;
      NA) na=$((na + 1)) ;;
      PENDING) pending=$((pending + 1)) ;;
    esac
    printf '%s\t%s\n' "$id" "$status"
  done < "$path"
  echo "---"
  echo "DONE=$done NA=$na PENDING=$pending TOTAL=$total"
  if [ "$pending" -eq 0 ]; then
    echo "VEREDICTO: COMPLETO"
  else
    echo "VEREDICTO: INCOMPLETO ($pending pendientes)"
  fi
}

cmd_init() {
  local target="$1"
  local dir current_hash path stored_hash
  dir="$(target_dir "$target")"
  current_hash="$(compute_hash "$dir")"
  path="$(state_path "$target")"

  if [ -f "$path" ]; then
    stored_hash="$(read_hash "$path")"
    if [ "$stored_hash" = "$current_hash" ]; then
      echo "$target: estado sin cambios (el contenido del skill no cambió desde el último init)."
      print_status "$path"
      return 0
    fi
    echo "$target: el contenido cambió desde el último init — se reinicia el checklist completo." >&2
  else
    echo "$target: primer init — se crea el checklist."
  fi

  local tmp
  tmp="$(mktemp)"
  printf 'HASH\t%s\n' "$current_hash" > "$tmp"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\tPENDING\t\n' "$id" >> "$tmp"
  done < <(checklist_ids)
  mv "$tmp" "$path"
  print_status "$path"
}

cmd_mark() {
  local target="$1" id="$2" status="$3"
  shift 3
  local nota="$*"
  local path dir current_hash stored_hash

  path="$(require_state "$target")"
  dir="$(target_dir "$target")"
  current_hash="$(compute_hash "$dir")"
  stored_hash="$(read_hash "$path")"
  [ "$stored_hash" = "$current_hash" ] || err "El skill cambió desde el último init. Ejecutá init de nuevo antes de marcar nada."

  case "$status" in
    DONE|NA) ;;
    *) err "Estado inválido: '$status'. Debe ser DONE o NA." ;;
  esac

  checklist_ids | grep -qx "$id" || err "ID desconocido: '$id'. No aparece en validaciones.md."

  local tmp found=0
  tmp="$(mktemp)"
  while IFS=$'\t' read -r line_id line_status line_nota; do
    if [ "$line_id" = "HASH" ]; then
      printf '%s\t%s\n' "$line_id" "$line_status" >> "$tmp"
    elif [ "$line_id" = "$id" ]; then
      printf '%s\t%s\t%s\n' "$id" "$status" "$nota" >> "$tmp"
      found=1
    else
      printf '%s\t%s\t%s\n' "$line_id" "$line_status" "$line_nota" >> "$tmp"
    fi
  done < "$path"
  [ "$found" -eq 1 ] || { rm -f "$tmp"; err "ID '$id' no estaba en el estado (¿corriste init?)."; }
  mv "$tmp" "$path"
  echo "$target: $id=$status"
}

cmd_pending() {
  local target="$1"
  local path
  path="$(require_state "$target")"
  local any=0
  while IFS=$'\t' read -r id status _nota; do
    [ "$id" = "HASH" ] && continue
    if [ "$status" = "PENDING" ]; then
      echo "$id"
      any=1
    fi
  done < "$path"
  [ "$any" -eq 1 ] || echo "(sin puntos pendientes)"
}

cmd_status() {
  local target="$1"
  local path
  path="$(require_state "$target")"
  print_status "$path"
}

main() {
  local command="${1:-}"
  [ -n "$command" ] || err "Uso: validar_skill.sh <init|mark|pending|status> <skill> [args...]"
  shift

  case "$command" in
    init)
      [ $# -eq 1 ] || err "Uso: validar_skill.sh init <skill>"
      cmd_init "$1"
      ;;
    mark)
      [ $# -ge 3 ] || err "Uso: validar_skill.sh mark <skill> <id> <DONE|NA> [nota]"
      cmd_mark "$@"
      ;;
    pending)
      [ $# -eq 1 ] || err "Uso: validar_skill.sh pending <skill>"
      cmd_pending "$1"
      ;;
    status)
      [ $# -eq 1 ] || err "Uso: validar_skill.sh status <skill>"
      cmd_status "$1"
      ;;
    *)
      err "Comando desconocido: '$command'. Usá init, mark, pending o status."
      ;;
  esac
}

main "$@"
