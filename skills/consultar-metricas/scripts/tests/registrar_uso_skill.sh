#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../registrar_uso_skill.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para registrar_uso_skill.sh..."

# --- Payload real de un PreToolUse para el skill "consultar-metricas"
# (forma verificada empíricamente contra un hook real de Claude Code) ---
HOME_1="${TMP_DIR}/home-1"
payload_real='{"session_id":"abc","hook_event_name":"PreToolUse","tool_name":"Skill","tool_input":{"skill":"consultar-metricas","args":""},"tool_use_id":"toolu_1"}'

printf '%s' "$payload_real" | DOTSKILLS_HOME="$HOME_1" "$SCRIPT"

LOG_1="${HOME_1}/metricas/uso_skills.log"
if [ ! -f "$LOG_1" ]; then
  echo "TEST FAIL: no se creó el log de métricas." >&2
  exit 1
fi
if ! grep -q "	consultar-metricas\$" "$LOG_1"; then
  echo "TEST FAIL: el log no registró 'consultar-metricas' con el formato esperado." >&2
  cat "$LOG_1" >&2
  exit 1
fi
echo "PASS: un payload real registra el nombre del skill invocado."

# --- Dos invocaciones se acumulan como dos líneas ---
printf '%s' "$payload_real" | DOTSKILLS_HOME="$HOME_1" "$SCRIPT"
lineas=$(wc -l < "$LOG_1" | tr -d ' ')
if [ "$lineas" != "2" ]; then
  echo "TEST FAIL: se esperaban 2 líneas en el log tras 2 invocaciones, hay $lineas." >&2
  exit 1
fi
echo "PASS: invocaciones sucesivas se acumulan como líneas separadas."

# --- Payload sin campo 'skill': no debe romper, registra 'desconocido' ---
HOME_2="${TMP_DIR}/home-2"
payload_sin_skill='{"tool_name":"Skill","tool_input":{"args":"algo"}}'
printf '%s' "$payload_sin_skill" | DOTSKILLS_HOME="$HOME_2" "$SCRIPT"
if ! grep -q "	desconocido\$" "${HOME_2}/metricas/uso_skills.log"; then
  echo "TEST FAIL: un payload sin 'skill' debería registrar 'desconocido'." >&2
  exit 1
fi
echo "PASS: un payload sin campo 'skill' registra 'desconocido' en vez de fallar."

# --- Stdin vacío o JSON malformado: el hook nunca debe fallar (exit != 0) ---
HOME_3="${TMP_DIR}/home-3"
if ! printf '' | DOTSKILLS_HOME="$HOME_3" "$SCRIPT"; then
  echo "TEST FAIL: el hook no debe fallar con stdin vacío (bloquearía el tool call real)." >&2
  exit 1
fi
if ! printf 'esto no es json' | DOTSKILLS_HOME="$HOME_3" "$SCRIPT"; then
  echo "TEST FAIL: el hook no debe fallar con stdin malformado." >&2
  exit 1
fi
echo "PASS: stdin vacío o malformado no hacen fallar el hook."

echo "Todos los tests de registrar_uso_skill.sh pasaron."
