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
#     Imprime sha256(identificador) en hex: siempre 64 caracteres, sin
#     importar cuán largo sea el repo/owner/host (repos de GitLab con
#     subgrupos anidados, por ejemplo). No es legible a propósito — no
#     hace falta que lo sea: 'estado.sh init' graba el identificador,
#     la branch y el commit como texto plano en la cabecera de
#     DIAGNOSTICO.md, así que la legibilidad vive ahí, no en el nombre
#     de la carpeta.
#
# Si <dir> es un submódulo, resuelve siempre contra el superproyecto (el
# repo padre más externo, subiendo tantos niveles como haga falta) — la
# investigación queda linkeada al repo, nunca al submódulo, sin importar
# desde qué carpeta se invoque.
#
# Si no hay remoto "origin", usa el hash del commit raíz del repo (estable
# ante renombres de carpeta o clones a otro path, a diferencia de un path).
# Si ni eso hay (repo sin commits todavía), recién ahí cae a la ruta local
# absoluta como último recurso, y avisa por stderr (no aborta).

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

  # Si estamos dentro de un submódulo, subir al superproyecto — tantas
  # veces como haga falta, por si hay submódulos anidados.
  local super
  while super="$(git -C "$dir" rev-parse --show-superproject-working-tree 2>/dev/null)" && [ -n "$super" ]; do
    dir="$super"
  done

  local url
  if url=$(git -C "$dir" remote get-url origin 2>/dev/null); then
    normalizar_remoto "$url"
    return 0
  fi

  # Sin remoto: el hash del commit raíz identifica al repo sin importar
  # en qué path viva. Un repo con historias no relacionadas puede tener
  # más de una raíz — se ordenan para que el identificador sea siempre
  # el mismo sin importar el orden en que git las liste.
  local raiz
  raiz="$(git -C "$dir" rev-list --max-parents=0 HEAD 2>/dev/null | sort | tr '\n' ',')" || true
  raiz="${raiz%,}"
  if [ -n "$raiz" ]; then
    printf 'sin-remoto:%s\n' "$raiz"
    return 0
  fi

  local ruta
  ruta=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || ruta=$(cd "$dir" && pwd)
  echo "Aviso: no se encontró un remoto 'origin' ni commits en '$dir'; usando la ruta local como identificador temporal de proyecto." >&2
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

resolver_slug() {
  local dir="${1:-.}"
  local id
  id=$(resolver_identificador "$dir") || return 1
  printf '%s' "$id" | sha256_de
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
