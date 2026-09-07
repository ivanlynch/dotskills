#!/usr/bin/env bash
set -euo pipefail

# Arranca (o continúa) la fase "instrumentar". Si el archivo de la
# fase todavía no existe, lo crea desde TEMPLATE.md y precarga
# SINTOMA_USUARIO. En cualquier caso (nuevo o ya existente), agrega un
# registro ("ID:"/"SONDEO:"/"RESULTADO:"/"VEREDICTO:") por cada
# hipótesis que exista en DIAGNOSTICO.md y todavía no tenga uno acá —
# nunca pisa los registros que ya están, así que una ronda nueva de
# hipótesis de la Fase 3 se suma sin perder el trabajo ya hecho sobre
# las anteriores.
#
# No hay ningún campo que señale "la hipótesis vigente": es siempre la
# de menor ID sin VEREDICTO todavía, calculable con solo mirar el
# archivo — no hace falta que este script (ni el agente) la escriba en
# ningún lado.
#
# Uso: iniciar.sh <id>
# Imprime la ruta del archivo (nuevo o existente, ya actualizado).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ESTADO_SH="$SKILL_DIR/scripts/estado.sh"

err() { echo "$*" >&2; }

campo() {
  local archivo="$1" nombre="$2"
  grep -m1 -E "^${nombre}:" "$archivo" | sed -E "s/^${nombre}:[[:space:]]*//" || true
}

# Extrae "<campo>: valor" de DENTRO del registro delimitado por
# "ID: <id_h>" — no del archivo entero. Necesario porque HIPOTESIS
# (en DIAGNOSTICO.md) se repite una vez por registro.
campo_de_registro() {
  local archivo="$1" id_h="$2" nombre="$3"
  awk -v id="ID: $id_h" -v campo="^${nombre}:" '
    $0 == id { activo=1; next }
    activo && /^ID: / { activo=0 }
    activo && $0 ~ campo { sub(campo "[[:space:]]*", ""); print; exit }
  ' "$archivo" || true
}

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
  local id="${1:-}" destino sintoma diagnostico id_h
  [ -n "$id" ] || { err "Uso: $0 <id>"; exit 2; }

  destino="$("$ESTADO_SH" ruta-fase "$id" instrumentar)"

  if [ ! -f "$destino" ]; then
    cp "$FASE_DIR/TEMPLATE.md" "$destino"
    sintoma="$("$ESTADO_SH" campo "$id" SINTOMA_USUARIO)"
    [ -n "$sintoma" ] || { err "Error: no se encontró SINTOMA_USUARIO en DIAGNOSTICO.md — ¿corriste la Fase 0?"; exit 1; }
    escribir_campo "$destino" "SINTOMA_USUARIO" "$sintoma"
  fi

  diagnostico="$("$ESTADO_SH" dir "$id")/DIAGNOSTICO.md"
  if [ -z "$(grep -oE '^ID: H[0-9]+$' "$diagnostico" || true)" ]; then
    err "Error: no se encontró ninguna hipótesis (ID: H##) en DIAGNOSTICO.md — ¿acumulaste la Fase 3?"
    exit 1
  fi

  # Solo hipótesis con contenido real: la Fase 3 puede dejar hasta 2 de
  # los 5 registros sin HIPOTESIS (mínimo 3), y esos quedan igual en
  # DIAGNOSTICO.md al acumularse — no son hipótesis para probar, así
  # que no les generamos registro.
  local ids=()
  while IFS= read -r id_h; do
    [ -n "$id_h" ] || continue
    [ -n "$(campo_de_registro "$diagnostico" "$id_h" HIPOTESIS)" ] && ids+=("$id_h")
  done < <(grep -oE '^ID: H[0-9]+$' "$diagnostico" | sed -E 's/^ID: //' | sort -u)

  local bloque linea_marcador
  for id_h in "${ids[@]}"; do
    if ! grep -q "^ID: ${id_h}\$" "$destino"; then
      bloque="$(printf 'ID: %s\nSONDEO:\nRESULTADO:\nVEREDICTO:\n' "$id_h")"
      # Inserta antes de "## Condiciones de salida", no al final del
      # archivo — si no, un registro nuevo (de una ronda de hipótesis
      # posterior) quedaría después del checklist de cierre, donde
      # nadie lo espera encontrar. head/tail en vez de awk -v: el awk
      # de macOS (no es gawk) no acepta bien un -v con saltos de línea
      # adentro.
      linea_marcador="$(grep -n '^## Condiciones de salida$' "$destino" | head -1 | cut -d: -f1)"
      {
        head -n "$((linea_marcador - 1))" "$destino"
        printf '%s\n\n' "$bloque"
        tail -n "+${linea_marcador}" "$destino"
      } > "$destino.tmp"
      mv "$destino.tmp" "$destino"
    fi
  done

  echo "$destino"
}

main "$@"
