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
#     Imprime la versión sanitizada para nombre de carpeta: un prefijo
#     legible cortado a 60 caracteres + 8 caracteres de sha256 del
#     identificador completo (sin cortar), ej:
#     github.com-ivanlynch-mi-repo-a3f9c21e
#     El hash sale siempre del identificador ENTERO, nunca del prefijo ya
#     cortado — así dos proyectos que truncan al mismo prefijo no
#     terminan compartiendo carpeta. Longitud total siempre acotada
#     (~70 caracteres), sin importar cuán largo sea el repo/owner/host
#     (repos de GitLab con subgrupos anidados, por ejemplo).
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

sha256_de() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | cut -d' ' -f1
  else
    echo "Error: se necesita sha256sum o shasum para generar el slug." >&2
    return 1
  fi
}

MAX_PREFIJO=60

resolver_slug() {
  local dir="${1:-.}"
  local id
  id=$(resolver_identificador "$dir") || return 1

  local prefijo="${id//\//-}"
  prefijo="${prefijo#-}"
  prefijo="${prefijo:0:$MAX_PREFIJO}"
  prefijo="${prefijo%-}"

  local hash
  hash="$(printf '%s' "$id" | sha256_de | cut -c1-8)" || return 1

  printf '%s-%s\n' "$prefijo" "$hash"
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
