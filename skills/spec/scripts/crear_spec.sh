#!/usr/bin/env bash
set -euo pipefail

# Genera y completa incrementalmente un spec técnico (changes/<slug>/spec.md)
# a partir de un PRD ya aprobado por /idea, sin depender de que el LLM
# recuerde qué requerimientos RF-00N ya tienen escenario y cuáles no.
#
# Subcomandos:
#   crear_spec.sh init <ruta_prd> [ruta_salida]
#   crear_spec.sh add <ruta_spec> --escenario <RF-ID> "<nombre>" "<bloque_gherkin>" [--cerrar-lista]
#   crear_spec.sh add <ruta_spec> --escenario <RF-ID> --cerrar-lista
#   crear_spec.sh check <ruta_spec>
#   crear_spec.sh aprobar <ruta_spec>
#
# 'init' lee el PRD (debe estar en Estado Completo), extrae su título y cada
# encabezado '#### RF-00N: <título>', y genera una sección '## RF-00N: ...'
# por cada uno, con su propio placeholder de lista '{{ESCENARIOS_RF_00N}}'.
# Esto hace mecánico que el spec cubra exactamente los requerimientos del
# PRD: ninguno queda afuera ni se inventa uno nuevo, porque las secciones
# vienen scaffoldeadas antes de que el LLM escriba nada.
#
# A diferencia de crear_prd.sh (placeholders únicos en todo el archivo), acá
# el marcador de lista de escenarios se repite una vez por cada sección RF.
# Por eso cerrar una sección no puede basarse en un grep de todo el archivo
# (cerraría una sección vacía si otra ya tiene escenarios): se acota la
# búsqueda al rango entre el encabezado de esa sección y su propio marcador.
#
# 'check' es completitud MECÁNICA (¿falta alguna sección por cerrar?), no
# aprobación: no cambia el Estado del documento. 'aprobar' es la única forma
# de pasar de Borrador a Completo, y requiere que 'check' ya esté en OK.

uso() {
  cat >&2 <<EOF
Uso:
  $0 init <ruta_prd> [ruta_salida]
  $0 add <ruta_spec> --escenario <RF-ID> "<nombre>" "<bloque_gherkin>" [--cerrar-lista]
  $0 add <ruta_spec> --escenario <RF-ID> --cerrar-lista
  $0 check <ruta_spec>
  $0 aprobar <ruta_spec>
EOF
}

rf_marcador() {
  local rf_id="$1"
  printf '{{ESCENARIOS_%s}}' "$(printf '%s' "$rf_id" | tr '-' '_')"
}

cmd_init() {
  local ruta_prd="${1:-}"
  if [ -z "$ruta_prd" ] || [ ! -f "$ruta_prd" ]; then
    echo "Error: ruta de PRD inválida: '${ruta_prd:-}'." >&2
    uso
    exit 1
  fi
  if ! grep -qF '**Estado:** Completo' "$ruta_prd"; then
    echo "Error: el PRD '$ruta_prd' no está en Estado Completo. Aprobalo con /idea antes de generar el spec." >&2
    exit 1
  fi

  local titulo
  titulo=$(grep -m1 -E '^# PRD: ' "$ruta_prd" | sed -E 's/^# PRD: //')
  if [ -z "$titulo" ]; then
    echo "Error: no se encontró un título '# PRD: <titulo>' en '$ruta_prd'." >&2
    exit 1
  fi

  local rf_lines
  rf_lines=$(grep -oE '^#### RF-[0-9]+: .*$' "$ruta_prd" || true)
  if [ -z "$rf_lines" ]; then
    echo "Error: el PRD '$ruta_prd' no tiene ningún requerimiento RF-00N; no se puede generar spec." >&2
    exit 1
  fi

  local fecha
  fecha=$(date +%Y-%m-%d)
  local output_file="${2:-$(dirname "$ruta_prd")/spec.md}"
  local output_dir
  output_dir="$(dirname "$output_file")"
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
  fi

  {
    printf '# Spec: %s\n\n' "$titulo"
    printf '**Fecha:** %s\n' "$fecha"
    printf '**Estado:** Borrador\n'
    printf '**PRD:** %s\n\n' "$ruta_prd"
    printf -- '---\n'
    while IFS= read -r linea; do
      local id titulo_rf marcador
      id=$(printf '%s\n' "$linea" | sed -E 's/^#### (RF-[0-9]+): .*$/\1/')
      titulo_rf=$(printf '%s\n' "$linea" | sed -E 's/^#### RF-[0-9]+: (.*)$/\1/')
      marcador=$(rf_marcador "$id")
      printf '\n## %s: %s\n' "$id" "$titulo_rf"
      printf '%s\n' "$marcador"
    done <<< "$rf_lines"
  } > "$output_file"

  echo "Spec creado exitosamente en: $output_file"
  echo "Requerimientos a especificar (en orden):"
  while IFS= read -r linea; do
    local id titulo_rf
    id=$(printf '%s\n' "$linea" | sed -E 's/^#### (RF-[0-9]+): .*$/\1/')
    titulo_rf=$(printf '%s\n' "$linea" | sed -E 's/^#### RF-[0-9]+: (.*)$/\1/')
    echo "$id: $titulo_rf"
  done <<< "$rf_lines"
}

# Inserta un escenario (encabezado + bloque Gherkin, varias líneas) antes de
# la línea de marcador, dejando el marcador para poder seguir agregando
# escenarios a la misma sección.
agregar_escenario() {
  local ruta="$1" marcador="$2" nombre="$3" bloque="$4"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (RF-ID inválido para este spec, o ya se cerró esa sección)." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  {
    printf '### Escenario: %s\n' "$nombre"
    printf '%s\n' "$bloque"
  } >> "$tmp"
  tail -n +"$linea" "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Agregado escenario '$nombre' a '$marcador' en: $ruta"
}

# Cierra la lista de escenarios de UNA sección RF puntual. A diferencia de un
# cierre de lista de todo el archivo, acota la búsqueda de '### Escenario: '
# al rango entre el encabezado de esa sección y su propio marcador, para no
# confundirse con escenarios que ya tiene otra sección.
cerrar_lista_seccion() {
  local ruta="$1" rf_id="$2" marcador="$3"
  local heading_linea marcador_linea
  heading_linea=$(grep -nE "^## ${rf_id}: " "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$heading_linea" ]; then
    echo "Error: no se encontró la sección '$rf_id' en '$ruta'." >&2
    exit 1
  fi
  marcador_linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$marcador_linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró esta sección?)." >&2
    exit 1
  fi
  local tiene_escenario
  tiene_escenario=$(sed -n "$((heading_linea + 1)),$((marcador_linea - 1))p" "$ruta" | grep -cE '^### Escenario: ' || true)
  if [ "$tiene_escenario" -lt 1 ]; then
    echo "Error: no se agregó ningún escenario a '$rf_id' antes de cerrar. Agregá al menos uno antes de usar --cerrar-lista." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((marcador_linea - 1)) "$ruta" > "$tmp"
  tail -n +$((marcador_linea + 1)) "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Sección '$rf_id' cerrada en: $ruta"
}

cmd_add_escenario() {
  local ruta="$1"
  shift || true

  local rf_id="${1:-}"
  if [ -z "$rf_id" ]; then
    echo "Error: --escenario requiere un RF-ID, ej: --escenario RF-001 \"nombre\" \"bloque\"." >&2
    uso
    exit 1
  fi
  if ! printf '%s' "$rf_id" | grep -qE '^RF-[0-9]+$'; then
    echo "Error: RF-ID inválido: '$rf_id' (formato esperado: RF-00N)." >&2
    exit 1
  fi
  shift || true

  local nombre="" bloque="" cerrar=""
  if [ "${1:-}" = "--cerrar-lista" ]; then
    cerrar="--cerrar-lista"
    shift || true
  else
    nombre="${1:-}"
    shift || true
    if [ "${1:-}" = "--cerrar-lista" ]; then
      cerrar="--cerrar-lista"
      shift || true
    elif [ -n "${1:-}" ]; then
      bloque="$1"
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
  if [ -z "$nombre" ] && [ -z "$cerrar" ]; then
    echo "Error: --escenario requiere un nombre y un bloque Gherkin, ej: --escenario RF-001 \"Alta exitosa\" \"Dado ...\"." >&2
    uso
    exit 1
  fi
  if [ -n "$nombre" ] && [ -z "$bloque" ]; then
    echo "Error: --escenario requiere también el bloque Gherkin (Dado/Cuando/Entonces), ej: --escenario RF-001 \"Alta exitosa\" \"Dado ...\"." >&2
    exit 1
  fi

  local marcador
  marcador=$(rf_marcador "$rf_id")

  [ -n "$nombre" ] && agregar_escenario "$ruta" "$marcador" "$nombre" "$bloque"
  [ "$cerrar" = "--cerrar-lista" ] && cerrar_lista_seccion "$ruta" "$rf_id" "$marcador"
  return 0
}

cmd_add() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de spec inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  shift || true
  local flag="${1:-}"
  shift || true

  case "$flag" in
    --escenario) cmd_add_escenario "$ruta" "$@" ;;
    "")
      echo "Error: se requiere un flag, ej: --escenario." >&2
      uso
      exit 1
      ;;
    *)
      echo "Error: flag desconocido '$flag'." >&2
      uso
      exit 1
      ;;
  esac
}

# Devuelve (por stdout) los placeholders {{...}} pendientes en $ruta, uno por
# línea. Vacío si no queda ninguno. El regex incluye dígitos y guion bajo
# porque los marcadores de escenarios llevan el número de RF (RF_001).
placeholders_pendientes() {
  local ruta="$1"
  grep -oE '\{\{[A-Z0-9_]+\}\}' "$ruta" | sort -u || true
}

cmd_check() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de spec inválida: '${ruta:-}'." >&2
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
    echo "Error: ruta de spec inválida: '${ruta:-}'." >&2
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
  echo "Spec aprobado (Estado: Completo) en: $ruta"
}

main() {
  local sub="${1:-}"
  if [ -z "$sub" ]; then
    echo "Error: se requiere un subcomando (init, add, check, aprobar)." >&2
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
