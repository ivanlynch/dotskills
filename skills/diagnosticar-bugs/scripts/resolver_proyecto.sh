#!/usr/bin/env bash
set -euo pipefail

# Resuelve un identificador estable de proyecto a partir de su remoto git
# "origin", para no mezclar diagnósticos de distintos repos en una misma
# carpeta plana. Misma técnica que lib/resolver-proyecto.sh en better-sdd
# (otro repositorio), reimplementada acá porque diagnosticar-bugs no
# depende de better-sdd.
#
# Uso:
#   resolver_proyecto.sh identificador [<dir>]
#     Imprime el identificador canónico, ej: github.com/ivanlynch/mi-repo
#   resolver_proyecto.sh slug [<dir>]
#     Imprime la versión sanitizada para nombre de carpeta.
#
# Si el repo no tiene remoto "origin", usa la ruta local absoluta como
# identificador temporal y avisa por stderr (no aborta).

uso() {
  cat >&2 <<EOF
Uso:
  $0 identificador [<dir>]
  $0 slug [<dir>]
EOF
}

normalizar_remoto() {
  local url="$1"
  url="${url%.git}"
  if [[ "$url" == *"://"* ]]; then
    url="${url#*://}"
    url="${url#*@}"
  else
    url="${url#*@}"
    url="${url/://}"
  fi
  printf '%s\n' "$url"
}

resolver_identificador() {
  local dir="${1:-.}"
  local url
  if url=$(git -C "$dir" remote get-url origin 2>/dev/null); then
    normalizar_remoto "$url"
    return 0
  fi
  local ruta
  ruta=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || ruta=$(cd "$dir" && pwd)
  echo "Aviso: no se encontró un remoto 'origin' en '$dir'; usando la ruta local como identificador temporal de proyecto." >&2
  printf '%s\n' "$ruta"
}

resolver_slug() {
  local dir="${1:-.}"
  local id
  id=$(resolver_identificador "$dir") || return 1
  local slug="${id//\//-}"
  printf '%s\n' "${slug#-}"
}

main() {
  local subcomando="${1:-}"
  case "$subcomando" in
    identificador) resolver_identificador "${2:-.}" ;;
    slug) resolver_slug "${2:-.}" ;;
    *) uso; exit 2 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
