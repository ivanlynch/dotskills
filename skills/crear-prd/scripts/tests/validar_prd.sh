#!/usr/bin/env bash
# Test de validar_prd.sh: chequea el manejo de argumentos y la detección de
# secciones faltantes/presentes contra archivos temporales.
# Uso: scripts/tests/validar_prd.sh (sin argumentos)
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/validar_prd.sh"

pass=0
fail=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS  $desc"; pass=$((pass + 1))
  else
    echo "FAIL  $desc (esperado exit $expected, fue $actual)"; fail=$((fail + 1))
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "PASS  $desc"; pass=$((pass + 1))
  else
    echo "FAIL  $desc (no contiene: $needle)"; fail=$((fail + 1))
  fi
}

workdir="$(mktemp -d)"

out="$("$SCRIPT" 2>&1)"; code=$?
assert_exit "sin argumentos falla" 2 "$code"
assert_contains "sin argumentos muestra uso" "$out" "Uso:"

out="$("$SCRIPT" "$workdir/no-existe.md" 2>&1)"; code=$?
assert_exit "archivo inexistente falla" 1 "$code"
assert_contains "archivo inexistente informa el error" "$out" "ERROR"

cat > "$workdir/incompleto.md" <<'EOF'
# PRD: Ejemplo

## Por qué
Algo.

## Requisitos
Algo.
EOF
out="$("$SCRIPT" "$workdir/incompleto.md" 2>&1)"; code=$?
assert_exit "prd incompleto falla" 1 "$code"
assert_contains "prd incompleto marca Por qué como PASS" "$out" "PASS  ## Por qué"
assert_contains "prd incompleto marca Evidencia como FAIL" "$out" "FAIL  ## Evidencia (falta)"
assert_contains "prd incompleto informa cuántas faltan" "$out" "VEREDICTO: FALTAN"

cat > "$workdir/completo.md" <<'EOF'
# PRD: Ejemplo

## Por qué
Cliente, problema y métrica.

## Evidencia
Fuente citada.

## Supuestos
Supuesto con plan de validación.

## Alcance
Dentro y fuera.

## Requisitos
Given/When/Then.

## Requisitos no funcionales
Ninguno real por ahora.

## Riesgos abiertos
Ninguno.

## Changelog

| Fecha | Cambio | Quién |
| --- | --- | --- |
EOF
out="$("$SCRIPT" "$workdir/completo.md" 2>&1)"; code=$?
assert_exit "prd completo sale con exit 0" 0 "$code"
assert_contains "prd completo informa estructura completa" "$out" "VEREDICTO: ESTRUCTURA COMPLETA"
if printf '%s\n' "$out" | grep -q "^FAIL"; then
  echo "FAIL  prd completo no debería tener líneas FAIL"; fail=$((fail + 1))
else
  echo "PASS  prd completo no tiene líneas FAIL"; pass=$((pass + 1))
fi

rm -rf "$workdir"

echo "---"
echo "PASS=$pass FAIL=$fail"
if [ "$fail" -eq 0 ]; then
  echo "VEREDICTO: OK"
  exit 0
else
  echo "VEREDICTO: FALLÓ ($fail)"
  exit 1
fi
