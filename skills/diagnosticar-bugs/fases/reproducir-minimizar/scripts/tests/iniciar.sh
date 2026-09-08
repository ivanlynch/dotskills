#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../iniciar.sh"
ESTADO_SH="$SCRIPT_DIR/../../../../scripts/estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para iniciar.sh..."

REPO="$TMP_DIR/proyecto"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" remote add origin "https://github.com/ivanlynch/proyecto.git"
cd "$REPO"

# --- sin Fase 1 acumulada: falla porque no hay COMANDO ---
id=$(bash "$ESTADO_SH" init "el checkout devuelve 500 al pagar")
if bash "$SCRIPT" "$id" 2>/dev/null; then
  echo "TEST FAIL: iniciar.sh sin Fase 1 acumulada (sin COMANDO) debería fallar." >&2
  exit 1
fi
echo "PASS: iniciar.sh falla si todavía no se acumuló la Fase 1 (no hay COMANDO)."

# --- con Fase 1 acumulada: precarga SINTOMA_USUARIO y COMANDO ---
dir=$(bash "$ESTADO_SH" dir "$id")
printf 'SINTOMA_USUARIO: el checkout devuelve 500 al pagar\nMETODO: curl_http\nCOMANDO: curl -sf localhost:3000/checkout\nTIPO_BUCLE: automatico\nAJUSTES: ninguno\n' > "$dir/fases/construir-bucle.md"
bash "$ESTADO_SH" acumular "$id" "construir-bucle" "Fase: Construir bucle de feedback" >/dev/null

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

if ! grep -q "^COMANDO_MINIMIZADO: curl -sf localhost:3000/checkout$" "$destino"; then
  echo "TEST FAIL: COMANDO_MINIMIZADO debería precargarse con el COMANDO ya acumulado de la Fase 1." >&2
  cat "$destino" >&2
  exit 1
fi
echo "PASS: COMANDO_MINIMIZADO queda precargado con el COMANDO de la Fase 1."

if grep -q "^RECORTES:$" "$destino" && grep -q "^ES_MINIMO:$" "$destino"; then
  echo "PASS: el resto de los campos (RECORTES, ES_MINIMO) queda vacío, sin tocar."
else
  echo "TEST FAIL: RECORTES y ES_MINIMO deberían seguir vacíos tal como vienen del template." >&2
  cat "$destino" >&2
  exit 1
fi

# --- resumir sin acumular: no pisa el progreso ya escrito ---
sed -i -E 's/^RECORTES:$/RECORTES: saqué los campos opcionales del payload/' "$destino"
destino_resumido=$(bash "$SCRIPT" "$id")
if [ "$destino_resumido" != "$destino" ]; then
  echo "TEST FAIL: al resumir sin haber acumulado, iniciar.sh debería devolver la misma ruta." >&2
  exit 1
fi
if ! grep -q "^RECORTES: saqué los campos opcionales del payload$" "$destino_resumido"; then
  echo "TEST FAIL: iniciar.sh pisó RECORTES ya escrito en una fase todavía sin acumular." >&2
  cat "$destino_resumido" >&2
  exit 1
fi
echo "PASS: resumir la fase sin haber acumulado no pisa el progreso ya escrito."

# --- un valor con '/' y '&' no rompe la sustitución (motivo de usar awk, no sed) ---
comando_con_caracteres_especiales='curl -sf "localhost:3000/checkout?a=1&b=2"'
printf 'SINTOMA_USUARIO: otro sintoma\nMETODO: curl_http\nCOMANDO: %s\nTIPO_BUCLE: automatico\nAJUSTES: ninguno\n' "$comando_con_caracteres_especiales" > "$dir/fases/construir-bucle-2.md"
id2=$(bash "$ESTADO_SH" init "otro sintoma")
dir2=$(bash "$ESTADO_SH" dir "$id2")
cp "$dir/fases/construir-bucle-2.md" "$dir2/fases/construir-bucle.md"
bash "$ESTADO_SH" acumular "$id2" "construir-bucle" "Fase: Construir bucle de feedback" >/dev/null

destino2=$(bash "$SCRIPT" "$id2")
if ! grep -qF "COMANDO_MINIMIZADO: $comando_con_caracteres_especiales" "$destino2"; then
  echo "TEST FAIL: un COMANDO con '/' y '&' debería precargarse tal cual, sin que awk lo rompa." >&2
  cat "$destino2" >&2
  exit 1
fi
echo "PASS: un COMANDO con '/' y '&' se precarga sin romperse."

echo "Todos los tests de iniciar.sh pasaron."
