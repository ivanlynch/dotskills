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
#   estado.sh init
#     Genera un id nuevo (INV001, INV002, ... — incremental por proyecto,
#     ver ADR 0001) y crea $DIAGNOSTICOS_ROOT/<slug-proyecto>/<id>/ con
#     fases/ adentro y DIAGNOSTICO.md vacío. Imprime el id generado. Cada
#     llamada arranca una investigación nueva: no es idempotente, y no
#     acepta un id como argumento — para retomar una investigación
#     abierta, usá el id que ya te devolvió antes.
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
  $0 init
  $0 dir <id>
  $0 ruta-fase <id> <fase>
  $0 acumular <id> <fase> <titulo>
EOF
}

ROOT="${DIAGNOSTICOS_ROOT:-$HOME/Documents/diagnostics}"

ruta_base() {
  local slug
  slug="$("$RESOLVER" slug .)"
  printf '%s/%s\n' "$ROOT" "$slug"
}

# Asigna el siguiente número entero para <proyecto_dir>, leyendo y
# actualizando $proyecto_dir/.contador. Usa un directorio de lock
# (mkdir es atómico en POSIX, a diferencia de leer-y-escribir un
# archivo) para que dos "init" concurrentes en el mismo proyecto nunca
# se pisen — sin depender de flock, que no viene de fábrica en macOS.
contador_siguiente() {
  local proyecto_dir="$1"
  local contador_file="$proyecto_dir/.contador"
  local lock_dir="$proyecto_dir/.contador.lock"
  local intentos=0 actual siguiente

  while ! mkdir "$lock_dir" 2>/dev/null; do
    intentos=$((intentos + 1))
    if [ "$intentos" -ge 20 ]; then
      echo "Error: no se pudo tomar el lock del contador ('$lock_dir') tras 20 intentos. Si quedó de una corrida interrumpida, borralo a mano." >&2
      return 1
    fi
    sleep 1
  done
  trap 'rmdir "$lock_dir" 2>/dev/null' EXIT

  actual=0
  if [ -f "$contador_file" ]; then
    actual="$(cat "$contador_file")"
    [[ "$actual" =~ ^[0-9]+$ ]] || actual=0
  fi
  siguiente=$((actual + 1))
  printf '%s' "$siguiente" > "$contador_file"

  rmdir "$lock_dir"
  trap - EXIT

  printf '%s\n' "$siguiente"
}

cmd_init() {
  [ $# -eq 0 ] || { echo "Error: 'init' ya no recibe un id — lo genera automáticamente. Uso: estado.sh init" >&2; exit 2; }

  local proyecto_dir numero id dir
  proyecto_dir="$(ruta_base)"
  mkdir -p "$proyecto_dir"

  numero="$(contador_siguiente "$proyecto_dir")"
  id="$(printf 'INV%03d' "$numero")"
  dir="$proyecto_dir/$id"

  if [ -e "$dir" ]; then
    echo "Error interno: '$dir' ya existe pero el contador generó '$id' como nuevo. El contador ('$proyecto_dir/.contador') quedó desincronizado — revisalo a mano." >&2
    exit 1
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
  echo "$id"
}

cmd_dir() {
  local id="$1"
  local dir
  dir="$(ruta_base)/$id"
  [ -d "$dir" ] || { echo "Error: no existe el diagnóstico '$id' para este proyecto. Si es uno nuevo, corré primero: estado.sh init" >&2; exit 1; }
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
    init) cmd_init "$@" ;;
    dir) [ $# -eq 1 ] || { uso; exit 2; }; cmd_dir "$1" ;;
    ruta-fase) [ $# -eq 2 ] || { uso; exit 2; }; cmd_ruta_fase "$1" "$2" ;;
    acumular) [ $# -eq 3 ] || { uso; exit 2; }; cmd_acumular "$1" "$2" "$3" ;;
    *) uso; exit 2 ;;
  esac
}

main "$@"
