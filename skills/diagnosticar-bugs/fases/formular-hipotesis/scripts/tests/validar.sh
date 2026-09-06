#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para validar.sh (formular-hipotesis)..."

HIP_VALIDA="Si el timeout del checkout es muy corto es la causa, entonces subirlo hará desaparecer el bug"

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
  printf 'HIPOTESIS_1: %s\n' "$HIP_VALIDA"
  printf 'HIPOTESIS_2: %s\n' "$HIP_VALIDA"
  printf 'HIPOTESIS_3: %s\n' "$HIP_VALIDA"
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
  echo "TEST FAIL: sin ninguna hipótesis debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: sin ninguna hipótesis -> NOT_READY."

state="$TMP_DIR/formato-invalido.md"
nuevo_state "$state" \
  "HIPOTESIS_1: el timeout es muy corto" \
  "HIPOTESIS_2: $HIP_VALIDA" \
  "HIPOTESIS_3: $HIP_VALIDA" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: una hipótesis sin el formato 'si ... entonces' debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: hipótesis sin formato refutable -> NOT_READY."

state="$TMP_DIR/menos-de-3-sin-justificar.md"
nuevo_state "$state" \
  "HIPOTESIS_1: $HIP_VALIDA" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: menos de 3 hipótesis con JUSTIFICACION_MENOS_DE_3 en 'no aplica' debería dar NOT_READY (no aplica NO aplica acá)." >&2
  exit 1
fi
echo "PASS: menos de 3 hipótesis con 'no aplica' como justificación -> NOT_READY."

state="$TMP_DIR/menos-de-3-justificacion-corta.md"
nuevo_state "$state" \
  "HIPOTESIS_1: $HIP_VALIDA" \
  "JUSTIFICACION_MENOS_DE_3: es chico"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: una justificación demasiado corta debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: justificación demasiado corta -> NOT_READY."

state="$TMP_DIR/3-o-mas-sin-justificacion.md"
nuevo_state "$state" \
  "HIPOTESIS_1: $HIP_VALIDA" \
  "HIPOTESIS_2: $HIP_VALIDA" \
  "HIPOTESIS_3: $HIP_VALIDA"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: 3 o más hipótesis pero sin JUSTIFICACION_MENOS_DE_3 debería dar NOT_READY (el campo tiene que estar, aunque sea 'no aplica')." >&2
  exit 1
fi
echo "PASS: 3 o más hipótesis sin completar JUSTIFICACION_MENOS_DE_3 -> NOT_READY."

# --- caso feliz: 3 hipótesis válidas ---
state="$TMP_DIR/ok-3.md"
nuevo_state "$state" \
  "HIPOTESIS_1: $HIP_VALIDA" \
  "HIPOTESIS_2: $HIP_VALIDA" \
  "HIPOTESIS_3: $HIP_VALIDA" \
  "JUSTIFICACION_MENOS_DE_3: no aplica"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: 3 hipótesis válidas con formato correcto deberían dar READY. rc=$rc salida=$salida" >&2
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
  "HIPOTESIS_1: $HIP_VALIDA" \
  "JUSTIFICACION_MENOS_DE_3: el bug solo puede venir de un único punto de entrada en el código, no hay otra causa plausible"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: 1 hipótesis con justificación válida debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: 1 hipótesis con justificación explícita -> READY."

echo "Todos los tests de validar.sh (formular-hipotesis) pasaron."
