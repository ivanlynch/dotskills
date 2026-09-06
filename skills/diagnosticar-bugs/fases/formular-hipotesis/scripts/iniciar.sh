#!/usr/bin/env bash
set -euo pipefail

# Arranca la fase "formular hipótesis": copia TEMPLATE.md al destino y
# precarga SINTOMA_USUARIO extrayéndolo de DIAGNOSTICO.md — evita que
# el agente lo retipee a mano.
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
  local id="${1:-}" destino sintoma
  [ -n "$id" ] || { err "Uso: $0 <id>"; exit 2; }

  destino="$("$ESTADO_SH" ruta-fase "$id" formular-hipotesis)"
  cp "$FASE_DIR/TEMPLATE.md" "$destino"

  sintoma="$("$ESTADO_SH" campo "$id" SINTOMA_USUARIO)"
  [ -n "$sintoma" ] || { err "Error: no se encontró SINTOMA_USUARIO en DIAGNOSTICO.md — ¿corriste la Fase 0?"; exit 1; }

  escribir_campo "$destino" "SINTOMA_USUARIO" "$sintoma"

  echo "$destino"
}

main "$@"
