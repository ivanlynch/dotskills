#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../generar-reporte.sh"
ESTADO_SH="$SCRIPT_DIR/../estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para generar-reporte.sh..."

REPO="$TMP_DIR/proyecto"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" -c user.email="test@test.com" -c user.name="Test" -c commit.gpgsign=false commit -q --allow-empty -m "commit inicial"
git -C "$REPO" checkout -q -b fix/checkout-500
git -C "$REPO" remote add origin "https://github.com/ivanlynch/proyecto.git"
cd "$REPO"

id=$(bash "$ESTADO_SH" init "el checkout devuelve 500 al pagar")
dir=$(bash "$ESTADO_SH" dir "$id")

# --- sin Instrumentar acumulada todavía: falla ---
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: sin Fase 4 acumulada debería fallar." >&2
  exit 1
fi
echo "PASS: falla si todavía no se acumuló la Fase 4 (Instrumentar)."

# --- arma un DIAGNOSTICO.md como el que dejaría una investigación real ---
cat >> "$dir/DIAGNOSTICO.md" <<'EOF'

## Fase: Formular hipótesis

ID: H01
HIPOTESIS: Si el timeout es la causa, entonces subirlo arregla esto

ID: H02
HIPOTESIS: Si el payload llega vacio es la causa, entonces sanitizarlo arregla esto

ID: H03
HIPOTESIS:

## Fase: Instrumentar

ID: H01
SONDEO: breakpoint en processPayment, inspeccione timeout
RESULTADO: timeout en 30000ms, no es el problema
EVIDENCIA: /tmp/evidencia-h01.txt
VEREDICTO: descartada

ID: H02
SONDEO: breakpoint en el handler, inspeccione req.body
RESULTADO: amount llega undefined, coincide con la prediccion
EVIDENCIA: /tmp/evidencia-h02.txt
VEREDICTO: confirmada
EOF

# --- caso feliz: solo con Instrumentar acumulada (sin Fase 5 todavía) ---
salida=$(bash "$SCRIPT" "$id")
if [ "$salida" != "$dir/REPORT.md" ]; then
  echo "TEST FAIL: debería devolver la ruta '$dir/REPORT.md', devolvió '$salida'." >&2
  exit 1
fi
if [ ! -f "$salida" ]; then
  echo "TEST FAIL: el archivo REPORT.md debería existir." >&2
  exit 1
fi
echo "PASS: genera REPORT.md junto a DIAGNOSTICO.md."

if ! grep -q "^- \*\*Proyecto:\*\* github.com/ivanlynch/proyecto$" "$salida" \
   || ! grep -q "^- \*\*Branch:\*\* fix/checkout-500$" "$salida"; then
  echo "TEST FAIL: la cabecera debería traer Proyecto y Branch de DIAGNOSTICO.md." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: la cabecera trae Proyecto y Branch."

if ! grep -q "^el checkout devuelve 500 al pagar$" "$salida"; then
  echo "TEST FAIL: '## Problema' debería traer el SINTOMA_USUARIO tal cual." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: '## Problema' trae el síntoma reportado."

if ! grep -q "Causa confirmada (\*\*H02\*\*): Si el payload llega vacio es la causa, entonces sanitizarlo arregla esto" "$salida"; then
  echo "TEST FAIL: '## Diagnóstico' debería identificar H02 como la causa confirmada, con su HIPOTESIS." >&2
  cat "$salida" >&2
  exit 1
fi
if ! grep -q "Evidencia.*evidencia-h02.txt" "$salida"; then
  echo "TEST FAIL: '## Diagnóstico' debería incluir la ruta de EVIDENCIA de la hipótesis confirmada." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: '## Diagnóstico' identifica la causa confirmada con su evidencia."

if ! grep -q "| H01 | Si el timeout es la causa, entonces subirlo arregla esto | descartada |" "$salida" \
   || ! grep -q "| H02 | Si el payload llega vacio es la causa, entonces sanitizarlo arregla esto | confirmada |" "$salida"; then
  echo "TEST FAIL: '## Hipótesis evaluadas' debería listar H01 (descartada) y H02 (confirmada)." >&2
  cat "$salida" >&2
  exit 1
fi
if grep -q "| H03 |" "$salida"; then
  echo "TEST FAIL: H03 quedó en blanco en Fase 3 (no es una hipótesis real) — no debería aparecer en la tabla." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: la tabla de hipótesis lista H01/H02 con su veredicto, y omite el registro H03 en blanco."

if ! grep -q "Todavía no se acumuló la Fase 5" "$salida"; then
  echo "TEST FAIL: sin Fase 5 acumulada, '## Corrección aplicada' debería decirlo explícitamente." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: sin Fase 5 acumulada, lo indica en vez de dejar la sección vacía."

if ! grep -q "^## Análisis final$" "$salida" || ! grep -q "Completá acá un resumen" "$salida"; then
  echo "TEST FAIL: debería incluir '## Análisis final' con la guía en comentario, sin completar." >&2
  cat "$salida" >&2
  exit 1
fi
echo "PASS: incluye '## Análisis final' como placeholder para que lo complete el agente."

# --- con Fase 5 acumulada (con test de regresión): la sección de corrección se completa ---
cat >> "$dir/DIAGNOSTICO.md" <<'EOF'

## Fase: Corregir y testear

SE_PUEDE_TESTEAR: sí
TEST_DE_REGRESION: tests/checkout.test.js

CORRECCION: se agrego una validacion de amount antes de crear el charge
EOF

salida2=$(bash "$SCRIPT" "$id")
if ! grep -q "se agrego una validacion de amount antes de crear el charge" "$salida2"; then
  echo "TEST FAIL: '## Corrección aplicada' debería traer el valor de CORRECCION." >&2
  cat "$salida2" >&2
  exit 1
fi
if ! grep -q "test de regresión en \`tests/checkout.test.js\`" "$salida2"; then
  echo "TEST FAIL: con SE_PUEDE_TESTEAR: sí, debería mencionar el TEST_DE_REGRESION." >&2
  cat "$salida2" >&2
  exit 1
fi
echo "PASS: con Fase 5 acumulada (con test), '## Corrección aplicada' se completa con CORRECCION y el test."

# --- caso HALLAZGO (sin lugar para testear) en otra investigación ---
id2=$(bash "$ESTADO_SH" init "otro bug, sin lugar para testear")
dir2=$(bash "$ESTADO_SH" dir "$id2")
cat >> "$dir2/DIAGNOSTICO.md" <<'EOF'

## Fase: Formular hipótesis

ID: H01
HIPOTESIS: Si A es la causa, entonces cambiar A arregla esto

## Fase: Instrumentar

ID: H01
SONDEO: algo
RESULTADO: algo
EVIDENCIA: /tmp/evidencia-otra.txt
VEREDICTO: confirmada

## Fase: Corregir y testear

SE_PUEDE_TESTEAR: no
HALLAZGO: no habia caller aislable para un test

CORRECCION: se corrigio igual, sin test de regresion
EOF

salida3=$(bash "$SCRIPT" "$id2")
if ! grep -q "sin test de regresión — hallazgo: no habia caller aislable para un test" "$salida3"; then
  echo "TEST FAIL: con SE_PUEDE_TESTEAR: no, debería mencionar el HALLAZGO en vez de un test." >&2
  cat "$salida3" >&2
  exit 1
fi
echo "PASS: con Fase 5 acumulada (sin test, con HALLAZGO), '## Corrección aplicada' lo refleja."

# --- id inexistente ---
if bash "$SCRIPT" "INV999" 2>/dev/null; then
  echo "TEST FAIL: un id inexistente debería fallar." >&2
  exit 1
fi
echo "PASS: id inexistente falla."

echo "Todos los tests de generar-reporte.sh pasaron."
