#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para validar.sh (formular-hipotesis)..."

HIPOTESIS_VALIDA="Si la causa es que el timeout del checkout es muy corto, entonces subirlo hará desaparecer el bug"

# Arma un registro "ID: H##" + "HIPOTESIS: valor" (o vacío si no se
# pasa valor).
registro() {
  local id_hipotesis="$1" valor="${2:-}"
  printf 'ID: %s\nHIPOTESIS: %s\n\n' "$id_hipotesis" "$valor"
}

nuevo_state() {
  local archivo="$1"
  shift
  {
    printf 'SINTOMA_USUARIO: algo\n'
    for linea in "$@"; do printf '%s\n' "$linea"; done
    printf '\n## Condiciones de salida\n\n'
    printf '%s\n' \
      '- [ ] cantidad_valida' \
      '- [ ] formato_valido'
  } > "$archivo"
}

# --- Capa 1: completitud estructural ---

state="$TMP_DIR/sin-sintoma.md"
{
  registro H01 "$HIPOTESIS_VALIDA"
  registro H02 "$HIPOTESIS_VALIDA"
  registro H03 "$HIPOTESIS_VALIDA"
  printf 'JUSTIFICACION_MENOS_DE_3: no aplica\n'
} > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin SINTOMA_USUARIO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta SINTOMA_USUARIO -> NOT_READY."

state="$TMP_DIR/sin-hipotesis.md"
nuevo_state "$state" "JUSTIFICACION_MENOS_DE_3: no aplica"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin ningún registro ID: H## debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: sin ningún registro de hipótesis -> NOT_READY."

state="$TMP_DIR/formato-invalido.md"
nuevo_state "$state" \
  "$(registro H01 "el timeout es muy corto")" \
  "$(registro H02 "$HIPOTESIS_VALIDA")" \
  "$(registro H03 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: una hipótesis sin el formato 'si ... entonces' debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: hipótesis sin formato refutable -> NOT_READY."

state="$TMP_DIR/menos-de-3-sin-justificar.md"
nuevo_state "$state" \
  "$(registro H01 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: menos de 3 hipótesis con JUSTIFICACION_MENOS_DE_3 en 'no aplica' debería dar NOT_READY (no aplica NO aplica acá)." >&2
  exit 1
fi
echo "PASS: menos de 3 hipótesis con 'no aplica' como justificación -> NOT_READY."

state="$TMP_DIR/menos-de-3-justificacion-corta.md"
nuevo_state "$state" \
  "$(registro H01 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: es chico"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: una justificación demasiado corta debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: justificación demasiado corta -> NOT_READY."

state="$TMP_DIR/3-o-mas-sin-justificacion.md"
nuevo_state "$state" \
  "$(registro H01 "$HIPOTESIS_VALIDA")" \
  "$(registro H02 "$HIPOTESIS_VALIDA")" \
  "$(registro H03 "$HIPOTESIS_VALIDA")"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: 3 o más hipótesis pero sin JUSTIFICACION_MENOS_DE_3 debería dar NOT_READY (el campo tiene que estar, aunque sea 'no aplica')." >&2
  exit 1
fi
echo "PASS: 3 o más hipótesis sin completar JUSTIFICACION_MENOS_DE_3 -> NOT_READY."

# --- caso feliz: 3 hipótesis válidas ---
state="$TMP_DIR/ok-3.md"
nuevo_state "$state" \
  "$(registro H01 "$HIPOTESIS_VALIDA")" \
  "$(registro H02 "$HIPOTESIS_VALIDA")" \
  "$(registro H03 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: 3 hipótesis válidas con formato correcto deberían dar READY. rc=$rc salida=$salida" >&2
  cat "$state" >&2
  exit 1
fi
echo "PASS: 3 hipótesis válidas -> READY."

if grep -c '^- \[x\]' "$state" | grep -qx 2; then
  echo "PASS: READY tilda las 2 condiciones de salida en el archivo de la fase."
else
  echo "TEST FAIL: READY debería dejar las 2 condiciones tildadas en el archivo." >&2
  cat "$state" >&2
  exit 1
fi

# --- caso feliz: menos de 3, bien justificado ---
state="$TMP_DIR/ok-1-justificado.md"
nuevo_state "$state" \
  "$(registro H01 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: ya se descartaron todas las causas salvo una durante la instrumentación anterior"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: 1 hipótesis con justificación válida debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: 1 hipótesis con justificación explícita -> READY."

# --- caso de segunda ronda: IDs que arrancan en H06, no en H01 ---
state="$TMP_DIR/segunda-ronda.md"
nuevo_state "$state" \
  "$(registro H06 "$HIPOTESIS_VALIDA")" \
  "$(registro H07 "$HIPOTESIS_VALIDA")" \
  "$(registro H08 "$HIPOTESIS_VALIDA")" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: una ronda que arranca en H06 (no en H01) también debería poder dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: una ronda con IDs H06-H08 (segunda ronda) también valida bien — el chequeo es dinámico, no hardcodeado a H01-H05."

echo "Todos los tests de validar.sh (formular-hipotesis) pasaron."
