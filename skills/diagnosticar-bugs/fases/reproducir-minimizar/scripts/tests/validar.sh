#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para validar.sh (reproducir-minimizar)..."

ES_MINIMO_VALIDO="probé sacar cada campo restante uno por uno, todos vuelven el comando a verde"

nuevo_state() {
  local archivo="$1"
  shift
  {
    printf 'SINTOMA_USUARIO: algo\n'
    printf 'RECORTES: saqué los campos opcionales\n'
    printf 'ES_MINIMO: %s\n' "$ES_MINIMO_VALIDO"
    for linea in "$@"; do printf '%s\n' "$linea"; done
    printf '\n## Condiciones de salida\n\n'
    printf '%s\n' \
      '- [ ] reproduce_el_bug' \
      '- [ ] determinista'
  } > "$archivo"
}

# --- Capa 1: completitud estructural ---

state="$TMP_DIR/sin-comando.md"
nuevo_state "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin COMANDO_MINIMIZADO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta COMANDO_MINIMIZADO -> NOT_READY."

state="$TMP_DIR/sin-sintoma.md"
{
  printf 'RECORTES: ninguno\n'
  printf 'ES_MINIMO: %s\n' "$ES_MINIMO_VALIDO"
  printf 'COMANDO_MINIMIZADO: false\n'
} > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin SINTOMA_USUARIO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta SINTOMA_USUARIO -> NOT_READY (no llega a re-correr nada)."

state="$TMP_DIR/sin-recortes.md"
{
  printf 'SINTOMA_USUARIO: algo\n'
  printf 'ES_MINIMO: %s\n' "$ES_MINIMO_VALIDO"
  printf 'COMANDO_MINIMIZADO: false\n'
} > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin RECORTES debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta RECORTES -> NOT_READY."

state="$TMP_DIR/sin-es-minimo.md"
{
  printf 'SINTOMA_USUARIO: algo\n'
  printf 'RECORTES: ninguno\n'
  printf 'COMANDO_MINIMIZADO: false\n'
} > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin ES_MINIMO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta ES_MINIMO -> NOT_READY."

state="$TMP_DIR/es-minimo-trivial.md"
nuevo_state "$state" "COMANDO_MINIMIZADO: false"
sed -i -E 's/^ES_MINIMO:.*/ES_MINIMO: si/' "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un ES_MINIMO trivial ('si') debería dar NOT_READY, no alcanza con una confirmación corta." >&2
  exit 1
fi
echo "PASS: ES_MINIMO demasiado corto ('si') -> NOT_READY."

# --- Capa 2: verificación mecánica ---

# --- comando que siempre da verde (exit 0): ya no reproduce el bug ---
state="$TMP_DIR/siempre-verde.md"
nuevo_state "$state" "COMANDO_MINIMIZADO: true"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -eq 0 ] || [ "$salida" != "NOT_READY" ]; then
  echo "TEST FAIL: un comando que siempre da exit 0 debería ser NOT_READY (ya no reproduce el bug)." >&2
  exit 1
fi
echo "PASS: comando siempre en verde -> NOT_READY (reproduce_el_bug falla)."

# --- comando determinista que siempre falla: READY ---
state="$TMP_DIR/siempre-rojo.md"
nuevo_state "$state" "COMANDO_MINIMIZADO: false"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: un comando determinista que siempre falla debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: comando determinista que siempre falla -> READY."

if grep -c '^- \[x\]' "$state" | grep -qx 2; then
  echo "PASS: READY tilda las 2 condiciones de salida en el archivo de la fase."
else
  echo "TEST FAIL: READY debería dejar las 2 condiciones tildadas en el archivo." >&2
  cat "$state" >&2
  exit 1
fi

# --- comando no determinista (exit code distinto entre corridas) ---
contador_file="$TMP_DIR/contador"
echo 0 > "$contador_file"
comando_no_determinista="n=\$(cat '$contador_file'); n=\$((n+1)); echo \$n > '$contador_file'; exit \$((n % 2))"
state="$TMP_DIR/no-determinista.md"
nuevo_state "$state" "COMANDO_MINIMIZADO: $comando_no_determinista"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un comando con exit codes distintos entre corridas debería ser NOT_READY." >&2
  exit 1
fi
echo "PASS: comando no determinista -> NOT_READY."

# --- comando que se cuelga (timeout) ---
state="$TMP_DIR/colgado.md"
nuevo_state "$state" "COMANDO_MINIMIZADO: sleep 999"
if DIAGNOSTICAR_BUGS_UMBRAL_RAPIDO_S=1 bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un comando que se cuelga debería ser NOT_READY." >&2
  exit 1
fi
echo "PASS: comando que se cuelga (timeout) -> NOT_READY."

echo "Todos los tests de validar.sh (reproducir-minimizar) pasaron."
