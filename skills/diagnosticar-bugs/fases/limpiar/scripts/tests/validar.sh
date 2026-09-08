#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../validar.sh"
ESTADO_SH="$SCRIPT_DIR/../../../../scripts/estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para validar.sh (limpiar)..."

# Repo de prueba: el validador re-corre COMANDO y busca [DEBUG-...]
# desde el directorio actual, así que necesita un "proyecto" real.
REPO="$TMP_DIR/proyecto"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" -c user.email="test@test.com" -c user.name="Test" -c commit.gpgsign=false commit -q --allow-empty -m "commit inicial"
git -C "$REPO" remote add origin "https://github.com/ivanlynch/proyecto.git"
cd "$REPO"

# Crea una investigación nueva y le agrega, directo a DIAGNOSTICO.md,
# los campos que en un caso real dejarían acumuladas las Fases 1 y 5
# (acá no hace falta pasar por esas fases para probar Limpiar).
nueva_investigacion() {
  local id dir
  id=$(bash "$ESTADO_SH" init "bug de prueba para limpiar")
  dir=$(bash "$ESTADO_SH" dir "$id")
  for linea in "$@"; do printf '%s\n' "$linea" >> "$dir/DIAGNOSTICO.md"; done
  echo "$id"
}

# --- falta COMANDO (Fase 1 no acumulada) ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: sin COMANDO en DIAGNOSTICO.md debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta COMANDO -> NOT_READY."

# --- COMANDO todavía da rojo: el bug sigue reproduciéndose ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: false" "SE_PUEDE_TESTEAR: no" "HALLAZGO: no habia caller aislable para un test")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: COMANDO en rojo debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: COMANDO original todavía en rojo -> NOT_READY."

# --- SE_PUEDE_TESTEAR: sí, pero falta TEST_DE_REGRESION ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true" "SE_PUEDE_TESTEAR: sí")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: SE_PUEDE_TESTEAR sí sin TEST_DE_REGRESION debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta TEST_DE_REGRESION -> NOT_READY."

# --- SE_PUEDE_TESTEAR: no, pero falta HALLAZGO ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true" "SE_PUEDE_TESTEAR: no")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: SE_PUEDE_TESTEAR no sin HALLAZGO debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta HALLAZGO -> NOT_READY."

# --- Fase 5 no acumulada: falta SE_PUEDE_TESTEAR entero ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: sin SE_PUEDE_TESTEAR debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: falta SE_PUEDE_TESTEAR (Fase 5 sin acumular) -> NOT_READY."

# --- instrumentación [DEBUG-...] sin eliminar ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true" "SE_PUEDE_TESTEAR: no" "HALLAZGO: no habia caller aislable para un test")
echo "console.log('[DEBUG-a4f2] valor:', x)" > "$REPO/rastro.js"
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: instrumentación [DEBUG-...] sin eliminar debería dar NOT_READY." >&2
  rm -f "$REPO/rastro.js"
  exit 1
fi
echo "PASS: queda instrumentación [DEBUG-...] -> NOT_READY."
rm -f "$REPO/rastro.js"

# --- caso feliz: con test de regresión ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true" "SE_PUEDE_TESTEAR: sí" "TEST_DE_REGRESION: tests/checkout.test.js")
salida=$(bash "$SCRIPT" "$id" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: caso feliz con test de regresión debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: COMANDO en verde + test de regresión documentado -> READY."

# --- caso feliz: sin punto de entrada, con HALLAZGO ---
id=$(nueva_investigacion "TIPO_BUCLE: automatico" "COMANDO: true" "SE_PUEDE_TESTEAR: no" "HALLAZGO: no habia caller aislable para un test")
salida=$(bash "$SCRIPT" "$id" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: caso feliz con HALLAZGO documentado debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: COMANDO en verde + HALLAZGO documentado (sin test) -> READY."

# --- TIPO_BUCLE hitl: no penaliza no poder re-correr el COMANDO ---
id=$(nueva_investigacion "TIPO_BUCLE: hitl" "COMANDO: bash hitl-loop.template.sh" "SE_PUEDE_TESTEAR: sí" "TEST_DE_REGRESION: tests/checkout.test.js")
salida=$(bash "$SCRIPT" "$id" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" -ne 0 ] || [ "$salida" != "READY" ]; then
  echo "TEST FAIL: TIPO_BUCLE hitl con el resto en orden debería dar READY. rc=$rc salida=$salida" >&2
  exit 1
fi
echo "PASS: TIPO_BUCLE hitl no bloquea el resultado — se avisa por stderr, no cuenta como motivo."

# --- id inexistente ---
if bash "$SCRIPT" "INV999" 2>/dev/null; then
  echo "TEST FAIL: un id inexistente debería dar NOT_READY." >&2
  exit 1
fi
echo "PASS: id inexistente -> NOT_READY."

echo "Todos los tests de validar.sh (limpiar) pasaron."
