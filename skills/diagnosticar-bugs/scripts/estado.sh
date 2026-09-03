#!/usr/bin/env bash
set -euo pipefail

# Estado persistido de un diagnóstico en curso, fuera del proyecto (mismo
# patrón que investigar/scripts/crear-estructura-investigacion.sh), pero
# anidado por proyecto para no mezclar diagnósticos de repos distintos en
# una carpeta plana — misma técnica que resolver_proyecto.sh (adaptada de
# lib/resolver-proyecto.sh en better-sdd): el proyecto se identifica por
# su remoto git "origin" desde el directorio donde corras este script.
#
# Uso:
#   estado.sh init <id>
#     Crea $DIAGNOSTICOS_ROOT/<slug-proyecto>/<id>/ (si no existe) con
#     fases/ adentro y DIAGNOSTICO.md vacío. No sobrescribe un
#     diagnóstico existente.
#   estado.sh dir <id>
#     Imprime la ruta de la carpeta del diagnóstico. Falla si no existe.
#   estado.sh ruta-fase <id> <fase>
#     Imprime la ruta de fases/<fase>.md dentro del diagnóstico.
#   estado.sh acumular <id> <fase> <titulo>
#     Agrega el contenido de fases/<fase>.md a DIAGNOSTICO.md, bajo un
#     encabezado "## <titulo>". No se puede llamar dos veces para la misma
#     fase (falla si ya está acumulada) — evita duplicar una fase que se
#     re-valida por error.
#
# DIAGNOSTICOS_ROOT (default: ~/Documents/diagnostics) es la raíz de
# todos los proyectos; se puede sobreescribir para tests o para aislar
# corridas.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$SCRIPT_DIR/resolver_proyecto.sh"

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

ruta_base() {
  local slug
  slug="$("$RESOLVER" slug .)"
  printf '%s/%s\n' "$ROOT" "$slug"
}

cmd_init() {
  local id="$1"
  id_valido "$id" || { echo "Error: identificador inválido: '$id' (minúsculas, números y guiones, 4-64 caracteres)." >&2; exit 2; }

  local dir
  dir="$(ruta_base)/$id"
  if [ -d "$dir" ]; then
    echo "$dir"
    return 0
  fi

  mkdir -p "$dir/fases"

  # Proyecto, branch y commit quedan grabados en el momento del init, no
  # en el nombre de la carpeta: los nombres de branch se renombran o se
  # borran, y meterlos en el path los haría mentir con el tiempo. Esto es
  # el registro de verdad de "sobre qué estabas parado" al arrancar.
  local proyecto branch commit
  proyecto="$("$RESOLVER" identificador .)"
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(sin branch — no es un repo git o está en detached HEAD)")"
  commit="$(git rev-parse --short HEAD 2>/dev/null || echo "(sin commit)")"

  {
    printf '# Diagnóstico: %s\n\n' "$id"
    printf 'Proyecto: %s\n' "$proyecto"
    printf 'Branch:   %s\n' "$branch"
    printf 'Commit:   %s\n\n' "$commit"
    printf 'Generado por diagnosticar-bugs. Cada sección corresponde a una fase completada.\n'
  } > "$dir/DIAGNOSTICO.md"
  echo "$dir"
}

cmd_dir() {
  local id="$1"
  local dir
  dir="$(ruta_base)/$id"
  [ -d "$dir" ] || { echo "Error: no existe el diagnóstico '$id' para este proyecto. Corré primero: estado.sh init $id" >&2; exit 1; }
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
