#!/usr/bin/env bash
set -euo pipefail

# Crea y completa incrementalmente un borrador de PRD a partir de la
# plantilla de assets/template.md, sin depender de que el LLM recuerde
# reemplazar placeholders a mano.
#
# Subcomandos:
#   crear_prd.sh init "<titulo_de_la_feature>" [ruta_de_salida]
#   crear_prd.sh add <ruta_del_prd> --problema "<texto>"
#   crear_prd.sh add <ruta_del_prd> --objetivo "<texto>"
#   crear_prd.sh add <ruta_del_prd> --paso "<texto>" [--cerrar-lista]                        (repetible)
#   crear_prd.sh add <ruta_del_prd> --requerimiento "<título>" "<descripción>" [--cerrar-lista]  (repetible, asigna RF00N)
#   crear_prd.sh add <ruta_del_prd> --exclusion "<texto>" [--cerrar-lista]                   (repetible)
#   crear_prd.sh add <ruta_del_prd> --paso|--requerimiento|--exclusion --cerrar-lista
#   crear_prd.sh check <ruta_del_prd>
#   crear_prd.sh aprobar <ruta_del_prd>
#
# --cerrar-lista cierra la lista correspondiente (falla si quedaría vacía).
# Se puede combinar con el último ítem en la misma llamada, o usarse solo
# (sin texto) cuando el cierre se decide después de haber agregado el
# último ítem en una llamada previa. No aplica a --problema ni --objetivo.
#
# 'check' es completitud MECÁNICA (¿faltan placeholders?), no aprobación:
# no cambia el Estado del documento. 'aprobar' es la única forma de pasar
# de Borrador a Completo, y requiere que 'check' ya esté en OK — está
# pensado para usarse recién después de que el usuario aprobó explícitamente
# un resumen objetivo del PRD, no como paso automático del LLM.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${SCRIPT_DIR}/../assets/template.md"

uso() {
  cat >&2 <<EOF
Uso:
  $0 init "<titulo_de_la_feature>" [ruta_de_salida]
  $0 add <ruta_del_prd> --problema "<texto>"
  $0 add <ruta_del_prd> --objetivo "<texto>"
  $0 add <ruta_del_prd> --paso "<texto>" [--cerrar-lista]                        (repetible)
  $0 add <ruta_del_prd> --requerimiento "<título>" "<descripción>" [--cerrar-lista]  (repetible, asigna RF00N)
  $0 add <ruta_del_prd> --exclusion "<texto>" [--cerrar-lista]                   (repetible)
  $0 add <ruta_del_prd> --paso|--requerimiento|--exclusion --cerrar-lista
  $0 check <ruta_del_prd>
  $0 aprobar <ruta_del_prd>
EOF
}

cmd_init() {
  local titulo="${1:-}"
  if [ -z "$titulo" ]; then
    echo "Error: Se requiere el título de la característica." >&2
    uso
    exit 1
  fi
  if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: No se encontró la plantilla en '$TEMPLATE_PATH'." >&2
    exit 1
  fi

  local slug
  slug=$(echo "$titulo" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; s/ñ/n/g; s/ü/u/g' \
    | sed -E 's/[^a-z0-9]+/-/g' \
    | sed -E 's/^-+|-+$//g')
  if [ -z "$slug" ]; then
    slug="prd-feature"
  fi

  local fecha
  fecha=$(date +%Y-%m-%d)
  local output_file="${2:-changes/${slug}/prd.md}"
  local output_dir
  output_dir="$(dirname "$output_file")"
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
  fi

  # sed solo para TITULO/FECHA: son valores cortos y controlados (slug/fecha),
  # sin riesgo de caracteres especiales de sed.
  sed -e "s/{{TITULO}}/$titulo/g" -e "s/{{FECHA}}/$fecha/g" "$TEMPLATE_PATH" > "$output_file"

  echo "PRD creado exitosamente en: $output_file"
}

# Reemplaza una línea de placeholder única por el texto dado.
# No usa sed para el reemplazo (el texto del usuario puede traer '/', '&', etc.
# sin escapar), reconstruye el archivo con head/tail sobre el número de línea.
reemplazar_unico() {
  local ruta="$1" marcador="$2" valor="$3"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no está pendiente en '$ruta' (ya se completó o no existe)." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  printf '%s\n' "$valor" >> "$tmp"
  tail -n +$((linea + 1)) "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Actualizado '$marcador' en: $ruta"
}

# Cuenta cuántas líneas de ítem (que matchean $patron) hay inmediatamente
# arriba del marcador, para poder numerar el próximo ítem de una lista
# numerada de una sola línea por ítem. Se detiene en la primera línea que
# no matchea.
contar_items_lista() {
  local ruta="$1" marcador="$2" patron="$3"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  local n=0
  local i=$((linea - 1))
  while [ "$i" -ge 1 ]; do
    if sed -n "${i}p" "$ruta" | grep -qE "$patron"; then
      n=$((n + 1))
      i=$((i - 1))
    else
      break
    fi
  done
  echo "$n"
}

# Inserta un ítem con viñeta fija (lista simple) antes de la línea de
# marcador, dejando el marcador para poder seguir agregando ítems.
agregar_item() {
  local ruta="$1" marcador="$2" prefijo="$3" valor="$4"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró la lista?)." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  printf '%s%s\n' "$prefijo" "$valor" >> "$tmp"
  tail -n +"$linea" "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Agregado a '$marcador' en: $ruta"
}

# Inserta un ítem numerado (para el flujo principal, donde el orden importa)
# antes de la línea de marcador, calculando el número siguiente.
agregar_item_numerado() {
  local ruta="$1" marcador="$2" valor="$3"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró la lista?)." >&2
    exit 1
  fi
  local n siguiente
  n=$(contar_items_lista "$ruta" "$marcador" '^[0-9]+\. ')
  siguiente=$((n + 1))
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  printf '%s. %s\n' "$siguiente" "$valor" >> "$tmp"
  tail -n +"$linea" "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Agregado paso $siguiente a '$marcador' en: $ruta"
}

# Inserta un requerimiento funcional (título + descripción, dos líneas) antes
# del marcador, asignando el próximo ID RF00N disponible (sin guion: mantiene
# el mismo patrón que los IDs de escenario que /spec deriva de este, como
# RF001E001). El ID se calcula contando encabezados '#### RFNNN:' en todo el
# archivo, no solo la línea inmediata anterior al marcador (el bloque ocupa
# varias líneas, a diferencia de un ítem de una sola línea). No agrega una
# línea en blanco propia: el separador antes de la siguiente sección lo
# aporta el template, igual que con --paso y --exclusion.
agregar_requerimiento() {
  local ruta="$1" marcador="$2" titulo="$3" descripcion="$4"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró la lista?)." >&2
    exit 1
  fi
  local n siguiente id
  n=$(grep -cE '^#### RF[0-9]+: ' "$ruta" || true)
  siguiente=$((n + 1))
  id=$(printf 'RF%03d' "$siguiente")
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  {
    printf '#### %s: %s\n' "$id" "$titulo"
    printf '%s\n' "$descripcion"
  } >> "$tmp"
  tail -n +"$linea" "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Agregado $id a '$marcador' en: $ruta"
}

# Elimina la línea de marcador de una lista, solo si en todo el archivo ya
# hay al menos un ítem que matchee $patron (no se limita a la línea
# inmediata anterior, porque un requerimiento ocupa varias líneas).
cerrar_lista_marcador() {
  local ruta="$1" marcador="$2" patron="$3"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró esta lista?)." >&2
    exit 1
  fi
  if ! grep -qE "$patron" "$ruta"; then
    echo "Error: no se agregó ningún ítem antes de cerrar '$marcador'. Agregá al menos uno antes de usar --cerrar-lista." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  tail -n +$((linea + 1)) "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Lista '$marcador' cerrada en: $ruta"
}

cmd_add_requerimiento() {
  local ruta="$1"
  shift || true

  local titulo="" descripcion="" cerrar=""
  if [ "${1:-}" = "--cerrar-lista" ]; then
    cerrar="--cerrar-lista"
    shift || true
  else
    titulo="${1:-}"
    shift || true
    if [ "${1:-}" = "--cerrar-lista" ]; then
      cerrar="--cerrar-lista"
      shift || true
    elif [ -n "${1:-}" ]; then
      descripcion="$1"
      shift || true
      if [ "${1:-}" = "--cerrar-lista" ]; then
        cerrar="--cerrar-lista"
        shift || true
      fi
    fi
  fi

  if [ -n "${1:-}" ]; then
    echo "Error: argumento inesperado '$1'." >&2
    uso
    exit 1
  fi
  if [ -z "$titulo" ] && [ -z "$cerrar" ]; then
    echo "Error: --requerimiento requiere un título y una descripción, ej: --requerimiento \"Crear invitación\" \"Un administrador puede...\"." >&2
    uso
    exit 1
  fi
  if [ -n "$titulo" ] && [ -z "$descripcion" ]; then
    echo "Error: --requerimiento requiere también una descripción, ej: --requerimiento \"Crear invitación\" \"Un administrador puede...\"." >&2
    exit 1
  fi

  [ -n "$titulo" ] && agregar_requerimiento "$ruta" "{{REQUERIMIENTOS}}" "$titulo" "$descripcion"
  [ "$cerrar" = "--cerrar-lista" ] && cerrar_lista_marcador "$ruta" "{{REQUERIMIENTOS}}" '^#### RF[0-9]+: '
  return 0
}

cmd_add() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de PRD inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  shift || true
  local flag="${1:-}"
  shift || true

  if [ "$flag" = "--requerimiento" ]; then
    cmd_add_requerimiento "$ruta" "$@"
    return 0
  fi

  # El valor es opcional: si el siguiente token ya es --cerrar-lista, se
  # interpreta como "cerrar sin agregar nada nuevo".
  local valor="" cerrar=""
  if [ "${1:-}" = "--cerrar-lista" ]; then
    cerrar="--cerrar-lista"
    shift || true
  elif [ -n "${1:-}" ]; then
    valor="$1"
    shift || true
    if [ "${1:-}" = "--cerrar-lista" ]; then
      cerrar="--cerrar-lista"
      shift || true
    fi
  fi

  if [ -n "${1:-}" ]; then
    echo "Error: argumento inesperado '$1'." >&2
    uso
    exit 1
  fi
  if [ -z "$flag" ] || { [ -z "$valor" ] && [ -z "$cerrar" ]; }; then
    echo "Error: se requiere un flag y un texto, y/o --cerrar-lista, ej: --problema \"texto\"." >&2
    uso
    exit 1
  fi

  case "$flag" in
    --problema)
      if [ "$cerrar" = "--cerrar-lista" ]; then
        echo "Error: --cerrar-lista no aplica a --problema (no es una lista)." >&2
        exit 1
      fi
      reemplazar_unico "$ruta" "{{PROBLEMA}}" "$valor"
      ;;
    --objetivo)
      if [ "$cerrar" = "--cerrar-lista" ]; then
        echo "Error: --cerrar-lista no aplica a --objetivo (no es una lista)." >&2
        exit 1
      fi
      reemplazar_unico "$ruta" "{{OBJETIVO}}" "$valor"
      ;;
    --paso)
      [ -n "$valor" ] && agregar_item_numerado "$ruta" "{{FLUJO_PRINCIPAL}}" "$valor"
      [ "$cerrar" = "--cerrar-lista" ] && cerrar_lista_marcador "$ruta" "{{FLUJO_PRINCIPAL}}" '^[0-9]+\. '
      ;;
    --exclusion)
      [ -n "$valor" ] && agregar_item "$ruta" "{{OUT_OF_SCOPE}}" "- " "$valor"
      [ "$cerrar" = "--cerrar-lista" ] && cerrar_lista_marcador "$ruta" "{{OUT_OF_SCOPE}}" '^- '
      ;;
    *)
      echo "Error: flag desconocido '$flag'." >&2
      uso
      exit 1
      ;;
  esac
  return 0
}

# Devuelve (por stdout) los placeholders {{...}} pendientes en $ruta, uno
# por línea. Vacío si no queda ninguno. La usan tanto 'check' como
# 'aprobar', para no duplicar el criterio de completitud mecánica.
placeholders_pendientes() {
  local ruta="$1"
  grep -oE '\{\{[A-Z_]+\}\}' "$ruta" | sort -u || true
}

cmd_check() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de PRD inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  local pendientes
  pendientes=$(placeholders_pendientes "$ruta")
  if [ -n "$pendientes" ]; then
    echo "Placeholders pendientes en '$ruta':" >&2
    echo "$pendientes" >&2
    exit 1
  fi
  echo "OK: no quedan placeholders pendientes en '$ruta'."
}

cmd_aprobar() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de PRD inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  local pendientes
  pendientes=$(placeholders_pendientes "$ruta")
  if [ -n "$pendientes" ]; then
    echo "Error: no se puede aprobar, todavía quedan placeholders pendientes:" >&2
    echo "$pendientes" >&2
    exit 1
  fi
  local linea
  linea=$(grep -nF '**Estado:** Borrador' "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: no se encontró '**Estado:** Borrador' en '$ruta' (¿ya fue aprobado?)." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  printf '**Estado:** Completo\n' >> "$tmp"
  tail -n +$((linea + 1)) "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "PRD aprobado (Estado: Completo) en: $ruta"
}

main() {
  local sub="${1:-}"
  if [ -z "$sub" ]; then
    echo "Error: se requiere un subcomando (init, add, check)." >&2
    uso
    exit 1
  fi
  shift
  case "$sub" in
    init) cmd_init "$@" ;;
    add) cmd_add "$@" ;;
    check) cmd_check "$@" ;;
    aprobar) cmd_aprobar "$@" ;;
    *)
      echo "Error: subcomando desconocido: '$sub'." >&2
      uso
      exit 1
      ;;
  esac
}

main "$@"
