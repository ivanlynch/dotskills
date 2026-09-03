#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar_estructura.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para validar_estructura.sh..."

nuevo_state() {
  local archivo="$1"
  shift
  {
    printf 'SINTOMA_USUARIO: algo\n'
    printf 'METODO: test_fallido\n'
    for linea in "$@"; do printf '%s\n' "$linea"; done
    printf '\n## Condiciones de salida\n\n'
    printf '%s\n' \
      '- [ ] capaz_de_ponerse_en_rojo' \
      '- [ ] determinista' \
      '- [ ] rapido' \
      '- [ ] ejecutable_sin_supervision'
  } > "$archivo"
}

# --- falta COMANDO ---
state="$TMP_DIR/sin-comando.md"
nuevo_state "$state" "TIPO_BUCLE: automatico"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin COMANDO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta COMANDO -> NOT_READY."

# --- comando que siempre da verde (exit 0): nunca se pone en rojo ---
state="$TMP_DIR/siempre-verde.md"
nuevo_state "$state" "TIPO_BUCLE: automatico" "COMANDO: true"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -eq 0 ] || [ "$salida" != "NOT_READY" ]; then
  echo "TEST FAIL: un comando que siempre da exit 0 debería ser NOT_READY (nunca se pone en rojo)." >&2
  exit 1
fi
echo "PASS: comando siempre en verde -> NOT_READY (capaz_de_ponerse_en_rojo falla)."

# --- comando determinista, rápido, que siempre falla: READY ---
state="$TMP_DIR/siempre-rojo.md"
nuevo_state "$state" "TIPO_BUCLE: automatico" "COMANDO: false"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: un comando determinista, rápido, que siempre falla debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: comando determinista y rápido que siempre falla -> READY."

if grep -c '^- \[x\]' "$state" | grep -qx 4; then
  echo "PASS: READY tilda las 4 condiciones de salida en el state.md."
else
  echo "TEST FAIL: READY debería dejar las 4 condiciones tildadas en el archivo." >&2
  cat "$state" >&2
  exit 1
fi

# --- comando no determinista (exit code distinto entre corridas) ---
contador_file="$TMP_DIR/contador"
echo 0 > "$contador_file"
comando_no_determinista="n=\$(cat '$contador_file'); n=\$((n+1)); echo \$n > '$contador_file'; exit \$((n % 2))"
state="$TMP_DIR/no-determinista.md"
nuevo_state "$state" "TIPO_BUCLE: automatico" "COMANDO: $comando_no_determinista"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un comando con exit codes distintos entre corridas debería ser NOT_READY." >&2
  exit 1
fi
echo "PASS: comando no determinista -> NOT_READY."

# --- comando lento (por encima del umbral) ---
state="$TMP_DIR/lento.md"
nuevo_state "$state" "TIPO_BUCLE: automatico" "COMANDO: sleep 2; exit 1"
if DIAGNOSTICAR_BUGS_UMBRAL_RAPIDO_S=1 bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un comando que tarda más que el umbral debería ser NOT_READY." >&2
  exit 1
fi
echo "PASS: comando por encima del umbral de velocidad -> NOT_READY."

# --- HITL: sin corrida real pegada -> NOT_READY ---
state="$TMP_DIR/hitl-sin-corrida.md"
nuevo_state "$state" "TIPO_BUCLE: hitl" "COMANDO: bash hitl-loop.template.sh"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: HITL sin corrida real pegada debería ser NOT_READY." >&2
  exit 1
fi
echo "PASS: HITL sin corrida real documentada -> NOT_READY."

# --- HITL: con corrida real pegada -> READY, sin re-correr 3 veces ---
state="$TMP_DIR/hitl-con-corrida.md"
nuevo_state "$state" "TIPO_BUCLE: hitl" "COMANDO: bash hitl-loop.template.sh"
printf '\n## Corrida real\n\n```\n$ bash hitl-loop.template.sh\nERROR=s\nMENSAJE_ERROR=Failed to export: timeout after 30s\n```\n' >> "$state"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: HITL con corrida real documentada debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: HITL con corrida real documentada -> READY, sin pedirle a la persona que repita clicks."

if grep -qx -- '- \[x\] capaz_de_ponerse_en_rojo' "$state" && grep -qx -- '- \[x\] ejecutable_sin_supervision' "$state"; then
  echo "PASS: HITL tilda capaz_de_ponerse_en_rojo y ejecutable_sin_supervision sin salvedades."
else
  echo "TEST FAIL: HITL debería tildar esas dos condiciones sin nota (son ciertas por definición en HITL)." >&2
  cat "$state" >&2
  exit 1
fi
if grep -q -- '^- \[x\] determinista (confiado' "$state" && grep -q -- '^- \[x\] rapido (confiado' "$state"; then
  echo "PASS: HITL tilda determinista/rapido con la salvedad de que no se re-verificaron mecánicamente."
else
  echo "TEST FAIL: HITL debería tildar determinista/rapido pero con la salvedad de 'confiado'." >&2
  cat "$state" >&2
  exit 1
fi

echo "Todos los tests de validar_estructura.sh pasaron."
