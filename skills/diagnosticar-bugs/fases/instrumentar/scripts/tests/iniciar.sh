#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../iniciar.sh"
ESTADO_SH="$SCRIPT_DIR/../../../../scripts/estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para iniciar.sh (instrumentar)..."

REPO="$TMP_DIR/proyecto"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" remote add origin "https://github.com/ivanlynch/proyecto.git"
cd "$REPO"

id=$(bash "$ESTADO_SH" init "el checkout devuelve 500 al pagar")

# --- sin hipótesis acumuladas: falla ---
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: iniciar.sh sin Fase 3 acumulada (sin ID: H##) debería fallar." >&2
  exit 1
fi
echo "PASS: iniciar.sh falla si todavía no se acumuló ninguna hipótesis."

# --- con Fase 3 acumulada (H01-H03; H04 y H05 quedaron en blanco, como
# permite el mínimo de 3 de 5 — deben ignorarse, no son hipótesis) ---
dir=$(bash "$ESTADO_SH" dir "$id")
printf '\n## Fase: Formular hipótesis (H01-H03)\n\nID: H01\nHIPOTESIS: Si es la causa X, entonces pasa Y\n\nID: H02\nHIPOTESIS: Si es la causa X2, entonces pasa Y2\n\nID: H03\nHIPOTESIS: Si es la causa X3, entonces pasa Y3\n\nID: H04\nHIPOTESIS:\n\nID: H05\nHIPOTESIS:\n' >> "$dir/DIAGNOSTICO.md"

destino=$(bash "$SCRIPT" "$id")
if [ ! -f "$destino" ]; then
  echo "TEST FAIL: iniciar.sh debería devolver la ruta de un archivo que existe." >&2
  exit 1
fi
echo "PASS: iniciar.sh crea el archivo y devuelve su ruta."

if ! grep -q "^SINTOMA_USUARIO: el checkout devuelve 500 al pagar$" "$destino"; then
  echo "TEST FAIL: SINTOMA_USUARIO debería quedar precargado." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: SINTOMA_USUARIO queda precargado."

for n in H01 H02 H03; do
  if ! grep -q "^ID: ${n}\$" "$destino"; then
    echo "TEST FAIL: debería existir el registro ID: ${n}." >&2
    cat "$destino" >&2
    exit 1
  fi
done
if [ "$(grep -c '^SONDEO:$' "$destino")" -ne 3 ] || [ "$(grep -c '^RESULTADO:$' "$destino")" -ne 3 ] || [ "$(grep -c '^VEREDICTO:$' "$destino")" -ne 3 ]; then
  echo "TEST FAIL: debería haber exactamente 3 campos SONDEO/RESULTADO/VEREDICTO vacíos (uno por hipótesis real)." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: se agrega un registro (ID/SONDEO/RESULTADO/VEREDICTO) por cada hipótesis real."

if grep -qE "^ID: H0[45]\$" "$destino"; then
  echo "TEST FAIL: H04 y H05 quedaron en blanco en la Fase 3 (no son hipótesis) — no deberían generar registro." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: los registros H## sin HIPOTESIS (en blanco) no generan registro de sondeo."

# --- una segunda corrida no pisa el trabajo ya hecho ---
# Ojo: el comentario del header también contiene la palabra "SONDEO:",
# así que hace falta anclar a fin de línea (campo vacío), no un
# replace de substring suelto — si no, pisa el comentario en vez del
# registro de H01.
python3 - "$destino" <<'PY'
import re, sys
p = sys.argv[1]
c = open(p).read()
c = re.sub(r'^SONDEO:$', 'SONDEO: agregue un log en la funcion X', c, count=1, flags=re.MULTILINE)
c = re.sub(r'^RESULTADO:$', 'RESULTADO: el log nunca se disparo', c, count=1, flags=re.MULTILINE)
c = re.sub(r'^VEREDICTO:$', 'VEREDICTO: descartada', c, count=1, flags=re.MULTILINE)
open(p, "w").write(c)
PY

destino2=$(bash "$SCRIPT" "$id")
if [ "$destino2" != "$destino" ]; then
  echo "TEST FAIL: una segunda corrida de iniciar.sh con las mismas hipótesis debería devolver el mismo archivo." >&2
  exit 1
fi
if ! grep -q "^VEREDICTO: descartada$" "$destino2"; then
  echo "TEST FAIL: iniciar.sh no debería pisar un VEREDICTO ya completado al volver a correrlo." >&2
  cat "$destino2" >&2
  exit 1
fi
echo "PASS: una segunda corrida no pisa los veredictos ya completados."

# --- segunda ronda de hipótesis: agrega H06-H07 (H04/H05 ya estaban
# "usados", aunque en blanco — el sistema real nunca los reasigna) sin
# pisar H01-H03 ---
printf '\n## Fase: Formular hipótesis (H06-H07)\n\nID: H06\nHIPOTESIS: Si es la causa X6, entonces pasa Y6\n\nID: H07\nHIPOTESIS: Si es la causa X7, entonces pasa Y7\n' >> "$dir/DIAGNOSTICO.md"

destino3=$(bash "$SCRIPT" "$id")
for n in H06 H07; do
  if ! grep -q "^ID: ${n}\$" "$destino3"; then
    echo "TEST FAIL: debería agregarse el registro ID: ${n} para las hipótesis de la segunda ronda." >&2
    cat "$destino3" >&2
    exit 1
  fi
done
if ! grep -q "^VEREDICTO: descartada$" "$destino3"; then
  echo "TEST FAIL: agregar hipótesis nuevas no debería borrar el veredicto ya puesto en H01." >&2
  cat "$destino3" >&2
  exit 1
fi
echo "PASS: una segunda ronda de hipótesis agrega registros nuevos sin pisar los de la ronda anterior."

# --- los registros nuevos quedan antes de 'Condiciones de salida', no después ---
linea_condiciones=$(grep -n '^## Condiciones de salida$' "$destino3" | cut -d: -f1)
linea_h07=$(grep -n '^ID: H07$' "$destino3" | cut -d: -f1)
if [ "$linea_h07" -ge "$linea_condiciones" ]; then
  echo "TEST FAIL: el registro H07 debería quedar ANTES de 'Condiciones de salida', no después." >&2
  cat "$destino3" >&2
  exit 1
fi
echo "PASS: los registros de hipótesis quedan antes de 'Condiciones de salida', en el orden esperado."

echo "Todos los tests de iniciar.sh (instrumentar) pasaron."
