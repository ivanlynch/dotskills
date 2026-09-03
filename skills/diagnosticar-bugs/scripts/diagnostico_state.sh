#!/usr/bin/env bash
set -euo pipefail

# Estado persistido de un diagnóstico en curso, fuera del repo del proyecto
# (mismo patrón que investigar/scripts/crear-estructura-investigacion.sh):
# una carpeta por diagnóstico, con un archivo por fase y un acumulado global.
#
# Uso:
#   diagnostico_state.sh init <id>
#     Crea $DIAGNOSTICOS_ROOT/<id>/ (si no existe) con fases/ adentro y
#     DIAGNOSTICO.md vacío. No sobrescribe un diagnóstico existente.
#   diagnostico_state.sh dir <id>
#     Imprime la ruta de la carpeta del diagnóstico. Falla si no existe.
#   diagnostico_state.sh ruta-fase <id> <fase>
#     Imprime la ruta de fases/<fase>.md dentro del diagnóstico.
#   diagnostico_state.sh acumular <id> <fase> <titulo>
#     Agrega el contenido de fases/<fase>.md a DIAGNOSTICO.md, bajo un
#     encabezado "## <titulo>". No se puede llamar dos veces para la misma
#     fase (falla si ya está acumulada) — evita duplicar una fase que se
#     re-valida por error.
#
# DIAGNOSTICOS_ROOT (default: ~/Documents/diagnostics) es la raíz de todos
# los diagnósticos; se puede sobreescribir para tests o para aislar corridas.

uso() {
  cat >&2 <<EOF
Uso:
  $0 init <id>
  $0 dir <id>
  $0 ruta-fase <id> <fase>
  $0 acumular <id> <fase> <titulo>
EOF
}

ROOT="${DIAGNOSTICOS_ROOT:-$HOME/Documents/diagnostics}"

id_valido() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]{2,62}[a-z0-9]$ ]]
}

cmd_init() {
  local id="$1"
  id_valido "$id" || { echo "Error: identificador inválido: '$id' (minúsculas, números y guiones, 4-64 caracteres)." >&2; exit 2; }

  local dir="$ROOT/$id"
  if [ -d "$dir" ]; then
    echo "$dir"
    return 0
  fi

  mkdir -p "$dir/fases"
  {
    printf '# Diagnóstico: %s\n\n' "$id"
    printf 'Generado por diagnosticar-bugs. Cada sección corresponde a una fase completada.\n'
  } > "$dir/DIAGNOSTICO.md"
  echo "$dir"
}

cmd_dir() {
  local id="$1"
  local dir="$ROOT/$id"
  [ -d "$dir" ] || { echo "Error: no existe el diagnóstico '$id'. Corré primero: diagnostico_state.sh init $id" >&2; exit 1; }
  echo "$dir"
}

cmd_ruta_fase() {
  local id="$1" fase="$2" dir
  dir="$(cmd_dir "$id")"
  echo "$dir/fases/$fase.md"
}

cmd_acumular() {
  local id="$1" fase="$2" titulo="$3" dir fase_file global_file
  dir="$(cmd_dir "$id")"
  fase_file="$dir/fases/$fase.md"
  global_file="$dir/DIAGNOSTICO.md"

  [ -f "$fase_file" ] || { echo "Error: no existe '$fase_file'. Completá la fase antes de acumularla." >&2; exit 1; }
  grep -qF "## $titulo" "$global_file" && { echo "Error: la fase '$fase' ya está acumulada en DIAGNOSTICO.md (no se duplica)." >&2; exit 1; }

  {
    printf '\n## %s\n\n' "$titulo"
    cat "$fase_file"
    printf '\n'
  } >> "$global_file"
  echo "Acumulado: $titulo -> $global_file"
}

main() {
  local cmd="${1:-}"
  [ -n "$cmd" ] || { uso; exit 2; }
  shift

  case "$cmd" in
    init) [ $# -eq 1 ] || { uso; exit 2; }; cmd_init "$1" ;;
    dir) [ $# -eq 1 ] || { uso; exit 2; }; cmd_dir "$1" ;;
    ruta-fase) [ $# -eq 2 ] || { uso; exit 2; }; cmd_ruta_fase "$1" "$2" ;;
    acumular) [ $# -eq 3 ] || { uso; exit 2; }; cmd_acumular "$1" "$2" "$3" ;;
    *) uso; exit 2 ;;
  esac
}

main "$@"
