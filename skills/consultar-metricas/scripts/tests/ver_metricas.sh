#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../ver_metricas.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para ver_metricas.sh..."

# --- Sin registros todavía ---
HOME_VACIO="${TMP_DIR}/home-vacio"
mkdir -p "$HOME_VACIO"
salida_vacia=$(DOTSKILLS_HOME="$HOME_VACIO" "$SCRIPT")

if ! printf '%s' "$salida_vacia" | grep -qi "no hay registros"; then
  echo "TEST FAIL: debería avisar que no hay registros de uso todavía." >&2
  echo "$salida_vacia" >&2
  exit 1
fi
echo "PASS: sin registros, muestra un mensaje en vez de una tabla vacía."

# --- Agrega usos por skill, de más a menos ---
HOME_CON_DATOS="${TMP_DIR}/home-con-datos"
mkdir -p "$HOME_CON_DATOS/metricas"
LOG="${HOME_CON_DATOS}/metricas/uso_skills.log"
{
  printf '2026-01-01T00:00:00Z\tcrear-ticket\n'
  printf '2026-01-01T00:01:00Z\tcrear-ticket\n'
  printf '2026-01-01T00:02:00Z\tcrear-ticket\n'
  printf '2026-01-01T00:03:00Z\tentrevistar\n'
} > "$LOG"

salida=$(DOTSKILLS_HOME="$HOME_CON_DATOS" "$SCRIPT")

if ! printf '%s' "$salida" | grep -qE '^3[[:space:]]+crear-ticket$'; then
  echo "TEST FAIL: se esperaban 3 usos de 'crear-ticket'." >&2
  echo "$salida" >&2
  exit 1
fi
if ! printf '%s' "$salida" | grep -qE '^1[[:space:]]+entrevistar$'; then
  echo "TEST FAIL: se esperaba 1 uso de 'entrevistar'." >&2
  echo "$salida" >&2
  exit 1
fi

linea_ticket=$(printf '%s\n' "$salida" | grep -n '^3[[:space:]]\+crear-ticket$' | cut -d: -f1)
linea_entrevistar=$(printf '%s\n' "$salida" | grep -n '^1[[:space:]]\+entrevistar$' | cut -d: -f1)
if [ "$linea_ticket" -ge "$linea_entrevistar" ]; then
  echo "TEST FAIL: el skill con más usos debería listarse primero." >&2
  echo "$salida" >&2
  exit 1
fi
echo "PASS: agrega usos por skill y los ordena de más a menos."

echo "Todos los tests de ver_metricas.sh pasaron."
