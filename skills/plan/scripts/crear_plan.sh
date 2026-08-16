#!/usr/bin/env bash
set -euo pipefail

# Genera y completa incrementalmente un plan de implementación
# (changes/<slug>/plan.md) a partir de una spec ya aprobada por /spec, sin
# depender de que el LLM recuerde qué escenarios RF00NE00N ya están cubiertos
# por alguna tarea.
#
# Subcomandos:
#   crear_plan.sh init <ruta_spec> [ruta_salida]
#   crear_plan.sh add <ruta_plan> --tarea "<título>" "<descripción>" --verificacion "<texto>" [--depende-de <T00N> ...] --cubre <RF00NE00N> [...] [--cerrar-lista]
#   crear_plan.sh add <ruta_plan> --tarea --cerrar-lista
#   crear_plan.sh check <ruta_plan>
#   crear_plan.sh aprobar <ruta_plan>
#
# A diferencia de /spec (una sección scaffoldeada por cada RF00N), la
# relación tarea↔escenario acá es muchos-a-muchos: una tarea puede cubrir
# varios escenarios y un escenario puede necesitar varias tareas. Por eso no
# se scaffoldea nada por escenario: 'init' solo informa (por stdout) qué
# escenarios existen en la spec, y 'check'/'aprobar' verifican mecánicamente,
# releyendo la spec original, que cada uno quedó declarado como cubierto por
# al menos una tarea (campo "Cubre:" de algún bloque de tarea). También
# verifican que cada dependencia declarada ("Depende de:") apunte a un T00N
# que realmente existe en el plan.

uso() {
  cat >&2 <<EOF
Uso:
  $0 init <ruta_spec> [ruta_salida]
  $0 add <ruta_plan> --tarea "<título>" "<descripción>" --verificacion "<texto>" [--depende-de <T00N> ...] --cubre <RF00NE00N> [...] [--cerrar-lista]
  $0 add <ruta_plan> --tarea --cerrar-lista
  $0 check <ruta_plan>
  $0 aprobar <ruta_plan>
EOF
}

cmd_init() {
  local ruta_spec="${1:-}"
  if [ -z "$ruta_spec" ] || [ ! -f "$ruta_spec" ]; then
    echo "Error: ruta de spec inválida: '${ruta_spec:-}'." >&2
    uso
    exit 1
  fi
  if ! grep -qF '**Estado:** Completo' "$ruta_spec"; then
    echo "Error: la spec '$ruta_spec' no está en Estado Completo. Aprobala con /spec antes de generar el plan." >&2
    exit 1
  fi

  local titulo
  titulo=$(grep -m1 -E '^# Spec: ' "$ruta_spec" | sed -E 's/^# Spec: //')
  if [ -z "$titulo" ]; then
    echo "Error: no se encontró un título '# Spec: <titulo>' en '$ruta_spec'." >&2
    exit 1
  fi

  local escenario_lines
  escenario_lines=$(grep -oE '^### RF[0-9]+E[0-9]+: .*$' "$ruta_spec" || true)
  if [ -z "$escenario_lines" ]; then
    echo "Error: la spec '$ruta_spec' no tiene ningún escenario RF00NE00N; no se puede generar plan." >&2
    exit 1
  fi

  local fecha
  fecha=$(date +%Y-%m-%d)
  local output_file="${2:-$(dirname "$ruta_spec")/plan.md}"
  local output_dir
  output_dir="$(dirname "$output_file")"
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
  fi

  {
    printf '# Plan: %s\n\n' "$titulo"
    printf '**Fecha:** %s\n' "$fecha"
    printf '**Estado:** Borrador\n'
    printf '**Spec:** %s\n\n' "$ruta_spec"
    printf -- '---\n\n'
    printf '## Tareas\n'
    printf '{{TAREAS}}\n'
  } > "$output_file"

  echo "Plan creado exitosamente en: $output_file"
  echo "Escenarios a cubrir (en orden):"
  while IFS= read -r linea; do
    printf '%s\n' "$linea" | sed -E 's/^### (RF[0-9]+E[0-9]+): (.*)$/\1: \2/'
  done <<< "$escenario_lines"
}

# Cuenta cuántos bloques de tarea '### T[0-9]+: ' hay en todo el archivo, para
# asignar el próximo ID T00N. Es un conteo global (no scopeado): a diferencia
# de los escenarios de /spec, acá la lista de tareas es plana, una sola.
siguiente_id_tarea() {
  local ruta="$1" n
  n=$(grep -cE '^### T[0-9]+: ' "$ruta" || true)
  printf 'T%03d' "$((n + 1))"
}

# Inserta un bloque de tarea (encabezado con ID propio + descripción +
# verificación + dependencias + escenarios cubiertos) antes de la línea de
# marcador, dejando el marcador para poder seguir agregando tareas.
agregar_tarea() {
  local ruta="$1" marcador="$2" titulo="$3" descripcion="$4" verificacion="$5" depende="$6" cubre="$7"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró la lista de tareas?)." >&2
    exit 1
  fi
  local id
  id=$(siguiente_id_tarea "$ruta")
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  {
    printf '### %s: %s\n' "$id" "$titulo"
    printf '%s\n' "$descripcion"
    printf '**Verificación:** %s\n' "$verificacion"
    printf '**Depende de:** %s\n' "${depende:-Ninguna}"
    printf '**Cubre:** %s\n\n' "$cubre"
  } >> "$tmp"
  tail -n +"$linea" "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Agregada tarea '$id: $titulo' a '$marcador' en: $ruta"
}

# Elimina la línea de marcador de la lista plana de tareas, solo si ya hay al
# menos un bloque '### T[0-9]+: ' en el archivo.
cerrar_lista_tareas() {
  local ruta="$1" marcador="$2"
  local linea
  linea=$(grep -nF "$marcador" "$ruta" | head -1 | cut -d: -f1)
  if [ -z "$linea" ]; then
    echo "Error: '$marcador' no existe en '$ruta' (¿ya se cerró la lista?)." >&2
    exit 1
  fi
  if ! grep -qE '^### T[0-9]+: ' "$ruta"; then
    echo "Error: no se agregó ninguna tarea antes de cerrar. Agregá al menos una antes de usar --cerrar-lista." >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  head -n $((linea - 1)) "$ruta" > "$tmp"
  tail -n +$((linea + 1)) "$ruta" >> "$tmp"
  mv "$tmp" "$ruta"
  echo "Lista de tareas cerrada en: $ruta"
}

cmd_add_tarea() {
  local ruta="$1"
  shift || true

  if [ "${1:-}" = "--cerrar-lista" ]; then
    cerrar_lista_tareas "$ruta" "{{TAREAS}}"
    return 0
  fi

  local titulo="${1:-}" descripcion="${2:-}"
  if [ -z "$titulo" ] || [ -z "$descripcion" ]; then
    echo "Error: --tarea requiere un título y una descripción, ej: --tarea \"Crear endpoint\" \"El sistema expone...\"." >&2
    uso
    exit 1
  fi
  shift 2 || true

  local verificacion="" cerrar=""
  local -a depende=() cubre=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --verificacion)
        shift
        verificacion="${1:-}"
        [ -n "$verificacion" ] || { echo "Error: --verificacion requiere un texto." >&2; exit 1; }
        shift
        ;;
      --depende-de)
        shift
        while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
          depende+=("$1")
          shift
        done
        ;;
      --cubre)
        shift
        while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
          cubre+=("$1")
          shift
        done
        ;;
      --cerrar-lista)
        cerrar="--cerrar-lista"
        shift
        ;;
      *)
        echo "Error: argumento inesperado '$1'." >&2
        uso
        exit 1
        ;;
    esac
  done

  if [ -z "$verificacion" ]; then
    echo "Error: --tarea requiere --verificacion." >&2
    exit 1
  fi
  if [ "${#cubre[@]}" -eq 0 ]; then
    echo "Error: --tarea requiere --cubre con al menos un escenario RF00NE00N." >&2
    exit 1
  fi

  local dep
  for dep in "${depende[@]+"${depende[@]}"}"; do
    if ! printf '%s' "$dep" | grep -qE '^T[0-9]+$'; then
      echo "Error: '--depende-de $dep' no tiene formato de ID de tarea (T00N)." >&2
      exit 1
    fi
    if ! grep -qE "^### ${dep}: " "$ruta"; then
      echo "Error: '--depende-de $dep' no existe en el plan todavía. Agregá esa tarea antes de declararla como dependencia." >&2
      exit 1
    fi
  done

  local ruta_spec
  ruta_spec=$(grep -m1 -F '**Spec:** ' "$ruta" | sed -E 's/^\*\*Spec:\*\* //')
  local esc
  for esc in "${cubre[@]}"; do
    if ! printf '%s' "$esc" | grep -qE '^RF[0-9]+E[0-9]+$'; then
      echo "Error: '--cubre $esc' no tiene formato de ID de escenario (RF00NE00N)." >&2
      exit 1
    fi
    if [ -n "$ruta_spec" ] && [ -f "$ruta_spec" ] && ! grep -qE "^### ${esc}: " "$ruta_spec"; then
      echo "Error: '--cubre $esc' no existe como escenario en la spec '$ruta_spec'." >&2
      exit 1
    fi
  done

  local depende_str cubre_str
  depende_str="${depende[*]+"${depende[*]}"}"
  cubre_str="${cubre[*]}"

  agregar_tarea "$ruta" "{{TAREAS}}" "$titulo" "$descripcion" "$verificacion" "$depende_str" "$cubre_str"
  [ "$cerrar" = "--cerrar-lista" ] && cerrar_lista_tareas "$ruta" "{{TAREAS}}"
  return 0
}

cmd_add() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de plan inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  shift || true
  local flag="${1:-}"
  shift || true

  case "$flag" in
    --tarea) cmd_add_tarea "$ruta" "$@" ;;
    "")
      echo "Error: se requiere un flag, ej: --tarea." >&2
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

placeholders_pendientes() {
  local ruta="$1"
  grep -oE '\{\{[A-Z0-9_]+\}\}' "$ruta" | sort -u || true
}

# Completitud mecánica completa: sin placeholders pendientes, cada escenario
# de la spec original cubierto por al menos una tarea, y cada dependencia
# declarada apuntando a un T00N que existe. Imprime los problemas por stderr
# y devuelve 1 si hay alguno; no imprime nada y devuelve 0 si está todo bien.
# La comparten 'check' y 'aprobar' para no duplicar el criterio.
verificar_completo() {
  local ruta="$1" hay_error=0

  local pendientes
  pendientes=$(placeholders_pendientes "$ruta")
  if [ -n "$pendientes" ]; then
    echo "Placeholders pendientes en '$ruta':" >&2
    echo "$pendientes" >&2
    hay_error=1
  fi

  local ruta_spec
  ruta_spec=$(grep -m1 -F '**Spec:** ' "$ruta" | sed -E 's/^\*\*Spec:\*\* //')
  if [ -z "$ruta_spec" ] || [ ! -f "$ruta_spec" ]; then
    echo "Error: no se encontró la spec de origen ('$ruta_spec') referenciada en '$ruta'." >&2
    return 1
  fi

  local requeridos cubiertos faltantes
  requeridos=$(grep -oE '^### RF[0-9]+E[0-9]+: ' "$ruta_spec" | sed -E 's/^### (RF[0-9]+E[0-9]+): $/\1/' | sort -u)
  cubiertos=$(grep -oE '^\*\*Cubre:\*\* .*$' "$ruta" | sed -E 's/^\*\*Cubre:\*\* //' | tr ' ' '\n' | sort -u)
  faltantes=$(comm -23 <(printf '%s\n' "$requeridos") <(printf '%s\n' "$cubiertos") 2>/dev/null || true)
  faltantes=$(printf '%s\n' "$faltantes" | sed '/^$/d')
  if [ -n "$faltantes" ]; then
    echo "Escenarios de la spec sin ninguna tarea que los cubra:" >&2
    echo "$faltantes" >&2
    hay_error=1
  fi

  local dep_lines dep_linea dep_id
  dep_lines=$(grep -oE '^\*\*Depende de:\*\* .*$' "$ruta" | sed -E 's/^\*\*Depende de:\*\* //' || true)
  while IFS= read -r dep_linea; do
    [ -z "$dep_linea" ] && continue
    [ "$dep_linea" = "Ninguna" ] && continue
    for dep_id in $dep_linea; do
      if ! grep -qE "^### ${dep_id}: " "$ruta"; then
        echo "Dependencia inexistente: '$dep_id' no es ninguna tarea del plan." >&2
        hay_error=1
      fi
    done
  done <<< "$dep_lines"

  return "$hay_error"
}

cmd_check() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de plan inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  if ! verificar_completo "$ruta"; then
    exit 1
  fi
  echo "OK: no quedan placeholders pendientes y todos los escenarios de la spec están cubiertos en '$ruta'."
}

cmd_aprobar() {
  local ruta="${1:-}"
  if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
    echo "Error: ruta de plan inválida: '${ruta:-}'." >&2
    uso
    exit 1
  fi
  if ! verificar_completo "$ruta"; then
    echo "Error: no se puede aprobar mientras existan los problemas de arriba." >&2
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
  echo "Plan aprobado (Estado: Completo) en: $ruta"
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
