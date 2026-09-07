#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para validar.sh (instrumentar)..."

# Arma un registro completo "ID:/SONDEO:/RESULTADO:/VEREDICTO:".
registro() {
  local id_h="$1" sondeo="${2:-}" resultado="${3:-}" veredicto="${4:-}"
  printf 'ID: %s\nSONDEO: %s\nRESULTADO: %s\nVEREDICTO: %s\n\n' "$id_h" "$sondeo" "$resultado" "$veredicto"
}

nuevo_state() {
  local archivo="$1"
  shift
  {
    printf 'SINTOMA_USUARIO: algo\n'
    for linea in "$@"; do printf '%s\n' "$linea"; done
    printf '\n## Condiciones de salida\n\n- [ ] entrada_completa\n'
  } > "$archivo"
}

# --- Capa 1: completitud de la entrada vigente (calculada, sin campo) ---

state="$TMP_DIR/sin-sintoma.md"
registro H01 > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin SINTOMA_USUARIO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta SINTOMA_USUARIO -> NOT_READY."

state="$TMP_DIR/sin-registros.md"
printf 'SINTOMA_USUARIO: algo\n' > "$state"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: sin ningún registro ID: H## debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: sin ningún registro de hipótesis -> NOT_READY."

# --- la vigente es H01 (menor ID sin veredicto): sin sondeo/resultado -> NOT_READY ---
state="$TMP_DIR/vigente-incompleta.md"
nuevo_state "$state" "$(registro H01)" "$(registro H02)"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: la hipótesis vigente (H01) sin SONDEO/RESULTADO/VEREDICTO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta SONDEO/RESULTADO/VEREDICTO de la hipótesis vigente -> NOT_READY."

state="$TMP_DIR/veredicto-invalido.md"
nuevo_state "$state" "$(registro H01 "agregue un log" "el log se disparo" "tal vez")" "$(registro H02)"
if bash "$SCRIPT" "$state" 2>/dev/null; then
  echo "TEST FAIL: un VEREDICTO que no sea 'confirmada' ni 'descartada' debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: VEREDICTO con un valor inválido -> NOT_READY."

# --- con H01 ya descartada, la vigente pasa a ser H02 automáticamente (sin ningún campo que lo diga) ---
state="$TMP_DIR/vigente-avanza.md"
nuevo_state "$state" \
  "$(registro H01 "agregue un log en la funcion X" "el log nunca se disparo" "descartada")" \
  "$(registro H02)"
salida_stderr=$(bash "$SCRIPT" "$state" 2>&1 >/dev/null) || true
if ! printf '%s' "$salida_stderr" | grep -q "registro H02"; then
  echo "TEST FAIL: con H01 ya resuelta, la vigente debería ser H02 (el error debería mencionar H02, no H01)." >&2
  echo "$salida_stderr" >&2
  exit 1
fi
echo "PASS: con H01 resuelta, la entrada vigente pasa a ser H02 automáticamente."

# --- caso feliz: hipótesis confirmada ---
state="$TMP_DIR/ok-confirmada.md"
nuevo_state "$state" \
  "$(registro H01 "agregue un log en la funcion X" "el log nunca se disparo" "descartada")" \
  "$(registro H02 "breakpoint en la funcion Y" "el valor era null, tal como predecia la hipotesis" "confirmada")"
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: la entrada vigente (H02) completa con veredicto 'confirmada' debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: entrada vigente con veredicto 'confirmada' -> READY."

if grep -qx -- '- \[x\] entrada_completa' "$state"; then
  echo "PASS: READY tilda 'entrada_completa'."
else
  echo "TEST FAIL: READY debería tildar 'entrada_completa'." >&2
  cat "$state" >&2
  exit 1
fi

# --- agotamiento: todas las hipótesis conocidas tienen veredicto, ninguna confirmada ---
state="$TMP_DIR/agotado.md"
nuevo_state "$state" \
  "$(registro H01 "algo" "algo" "descartada")" \
  "$(registro H02 "algo" "algo" "descartada")"
salida_stderr=$(bash "$SCRIPT" "$state" 2>&1 >/dev/null) || true
salida=$(bash "$SCRIPT" "$state" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -eq 0 ] || [ "$salida" != "NOT_READY" ]; then
  echo "TEST FAIL: con todas las hipótesis descartadas y ninguna confirmada, debería dar NOT_READY (agotamiento)." >&2
  exit 1
fi
if ! printf '%s' "$salida_stderr" | grep -qi "volvé a la Fase 3"; then
  echo "TEST FAIL: el motivo de agotamiento debería indicar explícitamente volver a la Fase 3." >&2
  echo "$salida_stderr" >&2
  exit 1
fi
echo "PASS: con todas las hipótesis descartadas y ninguna confirmada -> NOT_READY, con el motivo de agotamiento."

echo "Todos los tests de validar.sh (instrumentar) pasaron."
