#!/usr/bin/env bash
set -euo pipefail

# Arranca la fase "reproducir y minimizar": copia TEMPLATE.md al
# destino y precarga SINTOMA_USUARIO y COMANDO_MINIMIZADO extrayéndolos
# de DIAGNOSTICO.md (ya los grabaron Fase 0 y Fase 1) — evita que el
# agente los retipee a mano, con el riesgo de copiarlos mal.
#
# Si el destino ya existe Y ya tiene SINTOMA_USUARIO precargado, no lo
# toca — evita pisar el recorte y las notas ya escritas si se retoma la
# fase después de un corte de sesión, antes de haber llegado a
# acumularla. Si existe pero SINTOMA_USUARIO todavía está vacío, es la
# plantilla en blanco que dejó una corrida anterior que falló antes de
# completar el precargado (por ejemplo, sin COMANDO todavía acumulado
# en ese momento) — en ese caso sí se reintenta.
#
# Uso: iniciar.sh <id>
# Imprime la ruta del archivo (nuevo, reintentado, o ya existente sin tocar).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ESTADO_SH="$SKILL_DIR/scripts/estado.sh"

err() { echo "$*" >&2; }

# Reemplaza el valor de "CAMPO: valor" en $1 por $3, sin tocar el resto
# del archivo. awk en vez de sed: el valor puede traer '/', '&' u otros
# caracteres que romperían una sustitución sed sin escapar.
escribir_campo() {
  local archivo="$1" campo="$2" valor="$3"
  awk -v campo="$campo" -v valor="$valor" \
    '$0 ~ "^" campo ":" { print campo ": " valor; next } { print }' \
    "$archivo" > "$archivo.tmp"
  mv "$archivo.tmp" "$archivo"
}

main() {
  local id="${1:-}" destino sintoma comando
  [ -n "$id" ] || { err "Uso: $0 <id>"; exit 2; }

  destino="$("$ESTADO_SH" ruta-fase "$id" reproducir-minimizar)"

  if [ -f "$destino" ] && grep -qE '^SINTOMA_USUARIO:[[:space:]]*\S' "$destino"; then
    echo "$destino"
    return 0
  fi

  cp "$FASE_DIR/TEMPLATE.md" "$destino"

  sintoma="$("$ESTADO_SH" campo "$id" SINTOMA_USUARIO)"
  comando="$("$ESTADO_SH" campo "$id" COMANDO)"

  [ -n "$sintoma" ] || { err "Error: no se encontró SINTOMA_USUARIO en DIAGNOSTICO.md — ¿corriste la Fase 0?"; exit 1; }
  [ -n "$comando" ] || { err "Error: no se encontró COMANDO en DIAGNOSTICO.md — ¿acumulaste la Fase 1?"; exit 1; }

  escribir_campo "$destino" "SINTOMA_USUARIO" "$sintoma"
  escribir_campo "$destino" "COMANDO_MINIMIZADO" "$comando"

  echo "$destino"
}

main "$@"
