#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../iniciar.sh"
ESTADO_SH="$SCRIPT_DIR/../../../../scripts/estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para iniciar.sh (formular-hipotesis)..."

REPO="$TMP_DIR/proyecto"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" remote add origin "https://github.com/ivanlynch/proyecto.git"
cd "$REPO"

id=$(bash "$ESTADO_SH" init "el checkout devuelve 500 al pagar")

destino=$(bash "$SCRIPT" "$id")
if [ ! -f "$destino" ]; then
  echo "TEST FAIL: iniciar.sh debería devolver la ruta de un archivo que existe." >&2
  exit 1
fi
echo "PASS: iniciar.sh copia la plantilla y devuelve su ruta."

if ! grep -q "^SINTOMA_USUARIO: el checkout devuelve 500 al pagar$" "$destino"; then
  echo "TEST FAIL: SINTOMA_USUARIO debería quedar precargado desde DIAGNOSTICO.md." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: SINTOMA_USUARIO queda precargado desde DIAGNOSTICO.md."

if grep -q "^HIPOTESIS_1:$" "$destino" && grep -q "^JUSTIFICACION_MENOS_DE_3:$" "$destino"; then
  echo "PASS: el resto de los campos queda vacío, sin tocar."
else
  echo "TEST FAIL: HIPOTESIS_1 y JUSTIFICACION_MENOS_DE_3 deberían seguir vacíos tal como vienen del template." >&2
  cat "$destino" >&2
  exit 1
fi

echo "Todos los tests de iniciar.sh (formular-hipotesis) pasaron."
