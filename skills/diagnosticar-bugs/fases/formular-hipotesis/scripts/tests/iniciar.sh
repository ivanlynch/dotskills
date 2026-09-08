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

for n in 01 02 03 04 05; do
  if ! grep -q "^ID: H${n}$" "$destino"; then
    echo "TEST FAIL: debería existir el registro ID: H${n} (primera ronda, arranca en H01)." >&2
    cat "$destino" >&2
    exit 1
  fi
done
echo "PASS: primera ronda agrega los registros H01 a H05."

if [ "$(grep -c '^HIPOTESIS:$' "$destino")" -ne 5 ]; then
  echo "TEST FAIL: debería haber exactamente 5 campos HIPOTESIS: vacíos." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: cada registro trae su campo HIPOTESIS: vacío."

if grep -q "^ID: H06$" "$destino"; then
  echo "TEST FAIL: la primera ronda no debería llegar a H06." >&2
  exit 1
fi
echo "PASS: la primera ronda no genera de más."

# --- resumir sin acumular: no pisa una HIPOTESIS ya redactada ---
# awk en vez de sed: "0,/regex/" (reemplazar solo la primera
# ocurrencia) es una extensión de GNU sed que el sed de macOS no trae.
awk '!hecho && /^HIPOTESIS:$/ { print "HIPOTESIS: Si el timeout es la causa, entonces subirlo arregla esto"; hecho=1; next } { print }' "$destino" > "$destino.tmp" && mv "$destino.tmp" "$destino"
destino_resumido=$(bash "$SCRIPT" "$id")
if [ "$destino_resumido" != "$destino" ]; then
  echo "TEST FAIL: al resumir sin haber acumulado, iniciar.sh debería devolver la misma ruta." >&2
  exit 1
fi
if ! grep -q "^HIPOTESIS: Si el timeout es la causa, entonces subirlo arregla esto$" "$destino_resumido"; then
  echo "TEST FAIL: iniciar.sh pisó una HIPOTESIS ya redactada en una ronda todavía sin acumular." >&2
  cat "$destino_resumido" >&2
  exit 1
fi
echo "PASS: resumir la fase sin haber acumulado no pisa hipótesis ya redactadas."

# --- segunda ronda: arranca en H06, no repite H01-H05 ---
printf '\n## Fase: Formular hipótesis (H01-H05)\n\nID: H01\nHIPOTESIS: algo\n\nID: H02\nHIPOTESIS: algo\n\nID: H03\nHIPOTESIS: algo\n\nID: H04\nHIPOTESIS:\n\nID: H05\nHIPOTESIS:\n' >> "$(bash "$ESTADO_SH" dir "$id")/DIAGNOSTICO.md"

destino2=$(bash "$SCRIPT" "$id")
for n in 06 07 08 09 10; do
  if ! grep -q "^ID: H${n}$" "$destino2"; then
    echo "TEST FAIL: una segunda ronda debería agregar H06 a H10, arrancando después del más alto ya usado." >&2
    cat "$destino2" >&2
    exit 1
  fi
done
if grep -qE "^ID: H0[1-5]$" "$destino2"; then
  echo "TEST FAIL: una segunda ronda no debería reintroducir H01-H05 en el archivo nuevo." >&2
  cat "$destino2" >&2
  exit 1
fi
echo "PASS: una segunda ronda arranca en H06, sin repetir los IDs de la ronda anterior."

echo "Todos los tests de iniciar.sh (formular-hipotesis) pasaron."
