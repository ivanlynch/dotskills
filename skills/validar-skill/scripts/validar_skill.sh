#!/usr/bin/env bash
# Registro determinístico y fail-closed para el checklist de /validar-skill.
#
# Para los puntos del checklist que se pueden comprobar mecánicamente (ver
# verificar_mecanico más abajo), 'mark' no confía en lo que diga quien
# invoca: corre la comprobación real (incluye ejecutar scripts/tests/*.sh de
# verdad) y rechaza el mark si contradice lo que encontró. Nunca se puede
# marcar DONE un punto mecánico que en los hechos no lo está.
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

# --- Lectura de frontmatter -------------------------------------------------

# Imprime las líneas del frontmatter YAML (entre el primer '---' y el
# segundo), sin las líneas delimitadoras.
frontmatter_lines() {
  local dir="$1"
  awk '
    /^---[[:space:]]*$/ { c++; if (c == 2) exit; next }
    c == 1 { print }
  ' "$dir/SKILL.md"
}

# Valor de un campo de primer nivel del frontmatter (sin indentación), sin
# comillas envolventes si las tiene. Vacío si el campo no existe.
frontmatter_field() {
  local dir="$1" campo="$2"
  frontmatter_lines "$dir" | grep -m1 -E "^${campo}:" | sed -E "s/^${campo}:[[:space:]]*//; s/^\"(.*)\"\$/\1/"
}

frontmatter_tiene_campo() {
  local dir="$1" campo="$2"
  frontmatter_lines "$dir" | grep -qE "^${campo}:"
}

# --- Verificación mecánica ---------------------------------------------------
#
# Corre la comprobación real para los IDs de validaciones.md que se pueden
# decidir sin criterio humano. Setea tres variables globales:
#   VERIFICADO  1 si este ID se pudo decidir mecánicamente, 0 si no.
#   VEREDICTO   DONE o NA — el único estado válido, cuando VERIFICADO=1.
#   DETALLE     explicación corta de por qué, para el mensaje de error o la nota.
#
# Los IDs que no aparecen acá (VERIFICADO=0) requieren criterio del agente
# que invoca 'mark' — ver SKILL.md paso 2/3.
verificar_mecanico() {
  local dir="$1" id="$2"
  VERIFICADO=0
  VEREDICTO=""
  DETALLE=""

  local name description
  name="$(frontmatter_field "$dir" name)"

  case "$id" in
    dir-nombre-coincide)
      VERIFICADO=1
      local nombre_dir
      nombre_dir="$(basename "$dir")"
      if [ "$nombre_dir" = "$name" ]; then
        VEREDICTO=DONE; DETALLE="directorio '$nombre_dir' coincide con name '$name'"
      else
        VEREDICTO=RECHAZAR; DETALLE="directorio '$nombre_dir' no coincide con name '$name'"
      fi
      ;;

    name-longitud)
      VERIFICADO=1
      local len=${#name}
      if [ "$len" -ge 1 ] && [ "$len" -le 64 ]; then
        VEREDICTO=DONE; DETALLE="$len caracteres, dentro de 1-64"
      else
        VEREDICTO=RECHAZAR; DETALLE="$len caracteres, fuera de 1-64"
      fi
      ;;

    name-charset)
      VERIFICADO=1
      if [[ "$name" =~ ^[a-z0-9-]+$ ]]; then
        VEREDICTO=DONE; DETALLE="solo minúsculas a-z, dígitos y guiones"
      else
        VEREDICTO=RECHAZAR; DETALLE="'$name' tiene caracteres fuera de a-z0-9-"
      fi
      ;;

    name-sin-guion-borde)
      VERIFICADO=1
      if [[ "$name" != -* && "$name" != *- ]]; then
        VEREDICTO=DONE; DETALLE="no empieza ni termina con guion"
      else
        VEREDICTO=RECHAZAR; DETALLE="'$name' empieza o termina con guion"
      fi
      ;;

    name-sin-guion-doble)
      VERIFICADO=1
      if [[ "$name" != *--* ]]; then
        VEREDICTO=DONE; DETALLE="sin guiones consecutivos"
      else
        VEREDICTO=RECHAZAR; DETALLE="'$name' tiene guiones consecutivos"
      fi
      ;;

    description-longitud)
      VERIFICADO=1
      description="$(frontmatter_field "$dir" description)"
      local len=${#description}
      if [ "$len" -ge 1 ] && [ "$len" -le 1024 ]; then
        VEREDICTO=DONE; DETALLE="$len caracteres, dentro de 1-1024"
      else
        VEREDICTO=RECHAZAR; DETALLE="$len caracteres, fuera de 1-1024"
      fi
      ;;

    cuerpo-longitud)
      VERIFICADO=1
      local lineas
      lineas="$(wc -l < "$dir/SKILL.md" | tr -d ' ')"
      if [ "$lineas" -lt 500 ]; then
        VEREDICTO=DONE; DETALLE="$lineas líneas, por debajo de 500"
      else
        VEREDICTO=RECHAZAR; DETALLE="$lineas líneas, no está por debajo de 500"
      fi
      ;;

    ubicacion-exclusiva)
      VERIFICADO=1
      local nombre_dir canonical otras encontrado abs
      nombre_dir="$(basename "$dir")"
      canonical="$(cd "$dir" && pwd)"
      otras=""
      while IFS= read -r encontrado; do
        abs="$(cd "$encontrado" && pwd)"
        [ "$abs" = "$canonical" ] && continue
        otras="$otras $encontrado"
      done < <(find . -type d -name "$nombre_dir" -not -path "./.git/*" -not -path "./.git" 2>/dev/null)
      if [ -z "$otras" ]; then
        VEREDICTO=DONE; DETALLE="vive únicamente en $dir"
      else
        VEREDICTO=RECHAZAR; DETALLE="también existe en:$otras"
      fi
      ;;

    scripts-bash-no-python)
      VERIFICADO=1
      if [ ! -d "$dir/scripts" ]; then
        VEREDICTO=NA; DETALLE="no existe scripts/"
      else
        local otros
        otros="$(find "$dir/scripts" -type f \( -name '*.py' -o -name '*.rb' -o -name '*.js' -o -name '*.mjs' -o -name '*.ts' -o -name '*.pl' \) 2>/dev/null | tr '\n' ' ')"
        if [ -z "$otros" ]; then
          VEREDICTO=DONE; DETALLE="todo lo que hay en scripts/ es bash"
        else
          VEREDICTO=RECHAZAR; DETALLE="scripts no-bash encontrados: $otros"
        fi
      fi
      ;;

    scripts-con-test)
      VERIFICADO=1
      if [ ! -d "$dir/scripts" ]; then
        VEREDICTO=NA; DETALLE="no existe scripts/"
      else
        local script base test_file faltan="" fallan=""
        while IFS= read -r script; do
          base="$(basename "$script")"
          test_file="$dir/scripts/tests/$base"
          [ -f "$test_file" ] || faltan="$faltan $base"
        done < <(find "$dir/scripts" -maxdepth 1 -type f -name '*.sh' 2>/dev/null)

        while IFS= read -r test_file; do
          if ! bash "$test_file" >/dev/null 2>&1; then
            fallan="$fallan $(basename "$test_file")"
          fi
        done < <(find "$dir/scripts/tests" -maxdepth 1 -type f -name '*.sh' 2>/dev/null)

        if [ -z "$faltan" ] && [ -z "$fallan" ]; then
          VEREDICTO=DONE; DETALLE="cada script tiene test y todos los tests pasan (corridos ahora)"
        else
          VEREDICTO=RECHAZAR
          DETALLE="sin test:${faltan:- (ninguno)}; tests que fallan al correrlos ahora:${fallan:- (ninguno)}"
        fi
      fi
      ;;

    license-formato|compatibility-formato|compatibility-necesidad-real|metadata-formato|metadata-claves-unicas|allowed-tools-formato)
      local campo
      case "$id" in
        license-formato) campo="license" ;;
        compatibility-formato|compatibility-necesidad-real) campo="compatibility" ;;
        metadata-formato|metadata-claves-unicas) campo="metadata" ;;
        allowed-tools-formato) campo="allowed-tools" ;;
      esac
      if ! frontmatter_tiene_campo "$dir" "$campo"; then
        VERIFICADO=1; VEREDICTO=NA; DETALLE="el frontmatter no define $campo"
      fi
      # Si el campo SÍ existe, no lo decidimos acá (el formato/necesidad real
      # todavía requiere criterio) — pero cmd_mark igual va a rechazar un
      # intento de marcarlo NA, porque el campo está presente.
      ;;
  esac
}

# Campo de frontmatter que gatea cada ID condicional de metadata (mismo
# mapeo que usa verificar_mecanico). Vacío si el ID no es uno de estos.
campo_condicional_de() {
  case "$1" in
    license-formato) echo "license" ;;
    compatibility-formato|compatibility-necesidad-real) echo "compatibility" ;;
    metadata-formato|metadata-claves-unicas) echo "metadata" ;;
    allowed-tools-formato) echo "allowed-tools" ;;
    *) echo "" ;;
  esac
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

  local VERIFICADO VEREDICTO DETALLE
  verificar_mecanico "$dir" "$id"

  if [ "$VERIFICADO" = "1" ]; then
    if [ "$status" != "$VEREDICTO" ]; then
      err "Verificación automática de '$id': el estado real es $VEREDICTO, no $status. ($DETALLE)"
    fi
    nota="[auto-verificado: $DETALLE]${nota:+ — $nota}"
  else
    local campo
    campo="$(campo_condicional_de "$id")"
    if [ -n "$campo" ] && [ "$status" = "NA" ] && frontmatter_tiene_campo "$dir" "$campo"; then
      err "El frontmatter define '$campo'; no se puede marcar '$id' como NA. Revisá el contenido y marcalo DONE con una justificación, o corregí/quitá el campo."
    fi
    [ -n "$nota" ] || err "Falta justificación para '$id'. Uso: mark <skill> $id $status \"<justificación>\""
  fi

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
