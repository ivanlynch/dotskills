#!/usr/bin/env bash
set -euo pipefail

# Arranca (o inicia una ronda nueva de) la fase "formular hipótesis":
# copia TEMPLATE.md al destino, precarga SINTOMA_USUARIO extrayéndolo
# de DIAGNOSTICO.md, y agrega 5 registros de hipótesis en blanco
# ("ID: H##" + "HIPOTESIS:") con IDs nuevos que nunca se repiten en
# toda la investigación — arrancan después del ID más alto ya usado,
# así una ronda nueva nunca pisa ni confunde hipótesis de una ronda
# anterior.
#
# Uso: iniciar.sh <id>
# Imprime la ruta del archivo ya inicializado.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ESTADO_SH="$SKILL_DIR/scripts/estado.sh"

err() { echo "$*" >&2; }

# awk en vez de sed: el valor puede traer '/', '&' u otros caracteres
# que romperían una sustitución sed sin escapar.
escribir_campo() {
  local archivo="$1" campo="$2" valor="$3"
  awk -v campo="$campo" -v valor="$valor" \
    '$0 ~ "^" campo ":" { print campo ": " valor; next } { print }' \
    "$archivo" > "$archivo.tmp"
  mv "$archivo.tmp" "$archivo"
}

main() {
  local id="${1:-}" destino sintoma proximo_id numero n bloque
  [ -n "$id" ] || { err "Uso: $0 <id>"; exit 2; }

  destino="$("$ESTADO_SH" ruta-fase "$id" formular-hipotesis)"
  cp "$FASE_DIR/TEMPLATE.md" "$destino"

  sintoma="$("$ESTADO_SH" campo "$id" SINTOMA_USUARIO)"
  [ -n "$sintoma" ] || { err "Error: no se encontró SINTOMA_USUARIO en DIAGNOSTICO.md — ¿corriste la Fase 0?"; exit 1; }
  escribir_campo "$destino" "SINTOMA_USUARIO" "$sintoma"

  proximo_id="$("$ESTADO_SH" proximo-id-hipotesis "$id")"
  numero="${proximo_id#H}"
  numero=$((10#$numero))

  # Command substitution ya recorta los saltos de línea finales, así
  # que el separador en blanco entre registros no deja un final sucio.
  bloque="$(for n in 0 1 2 3 4; do printf 'ID: H%02d\nHIPOTESIS:\n\n' "$((numero + n))"; done)"

  # Inserta los campos H## dentro de la sección "## Hipótesis" (antes
  # de la sección "Justificación"), no al final del archivo — si no,
  # quedarían después de "Condiciones de salida", donde nadie los
  # espera encontrar. head/tail en vez de awk -v: el awk de macOS (no
  # es gawk) no acepta bien un -v con saltos de línea adentro.
  local linea_marcador
  linea_marcador="$(grep -n '^## Justificación si hay menos de 3 hipótesis$' "$destino" | head -1 | cut -d: -f1)"
  {
    head -n "$((linea_marcador - 1))" "$destino"
    printf '%s\n\n' "$bloque"
    tail -n "+${linea_marcador}" "$destino"
  } > "$destino.tmp"
  mv "$destino.tmp" "$destino"

  echo "$destino"
}

main "$@"
