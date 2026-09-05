#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../estado.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
export DIAGNOSTICOS_ROOT="$TMP_DIR/diagnostics"

echo "Ejecutando tests para estado.sh..."

# Todas las pruebas corren "adentro" de un repo con remoto, porque
# estado.sh resuelve el proyecto (y por lo tanto la carpeta) a partir
# del remoto git del directorio donde se invoca.
REPO_A="$TMP_DIR/proyecto-a"
mkdir -p "$REPO_A"
git -C "$REPO_A" init -q
git -C "$REPO_A" -c user.email="test@test.com" -c user.name="Test" -c commit.gpgsign=false commit -q --allow-empty -m "commit inicial"
git -C "$REPO_A" checkout -q -b feature/export-fix
git -C "$REPO_A" remote add origin "https://github.com/ivanlynch/proyecto-a.git"
cd "$REPO_A"

# --- init genera el primer id como INV001 y crea la estructura esperada ---
id=$(bash "$SCRIPT" init "el checkout devuelve 500 al pagar")
if [ "$id" != "INV001" ]; then
  echo "TEST FAIL: el primer id de un proyecto debería ser 'INV001', fue '$id'." >&2
  exit 1
fi
echo "PASS: init genera 'INV001' como primer id de un proyecto."

dir=$(bash "$SCRIPT" dir "$id")
if [ ! -d "$dir" ] || [ ! -f "$dir/DIAGNOSTICO.md" ] || [ ! -d "$dir/fases" ]; then
  echo "TEST FAIL: init no creó la estructura esperada." >&2
  exit 1
fi
case "$dir" in
  "$DIAGNOSTICOS_ROOT"/[0-9a-f][0-9a-f]*/"$id")
    slug_generado="${dir#"$DIAGNOSTICOS_ROOT"/}"
    slug_generado="${slug_generado%/"$id"}"
    if ! [[ "$slug_generado" =~ ^[0-9a-f]{64}$ ]]; then
      echo "TEST FAIL: el slug de la carpeta debería ser sha256 en hex de 64 chars, es '$slug_generado'." >&2
      exit 1
    fi
    ;;
  *) echo "TEST FAIL: init no anidó la carpeta bajo el slug del proyecto. dir='$dir'" >&2; exit 1 ;;
esac
echo "PASS: init crea carpeta anidada bajo el slug (hash) del proyecto, fases/ y DIAGNOSTICO.md."

if ! grep -q "^Proyecto: github.com/ivanlynch/proyecto-a$" "$dir/DIAGNOSTICO.md" \
   || ! grep -q "^Branch:   feature/export-fix$" "$dir/DIAGNOSTICO.md" \
   || ! grep -qE "^Commit:   [0-9a-f]+$" "$dir/DIAGNOSTICO.md" \
   || ! grep -q "^SINTOMA_USUARIO: el checkout devuelve 500 al pagar$" "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: DIAGNOSTICO.md debería grabar proyecto, branch, commit y síntoma al momento del init." >&2
  cat "$dir/DIAGNOSTICO.md" >&2
  exit 1
fi
echo "PASS: init graba proyecto, branch, commit y síntoma en DIAGNOSTICO.md (ver ADR 0004)."

# --- init NO es idempotente: cada llamada arranca una investigación nueva ---
echo "contenido previo" >> "$dir/DIAGNOSTICO.md"
id2=$(bash "$SCRIPT" init "otro síntoma sin relación con el anterior")
if [ "$id2" != "INV002" ]; then
  echo "TEST FAIL: un segundo init en el mismo proyecto debería generar 'INV002', fue '$id2'." >&2
  exit 1
fi
if ! grep -q "contenido previo" "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: el segundo init no debería haber tocado la investigación anterior (INV001)." >&2
  exit 1
fi
dir2=$(bash "$SCRIPT" dir "$id2")
if [ "$dir2" = "$dir" ]; then
  echo "TEST FAIL: 'INV001' e 'INV002' no deberían resolver a la misma carpeta." >&2
  exit 1
fi
echo "PASS: cada init genera un id incremental nuevo, sin pisar investigaciones anteriores."

# --- init exige el síntoma: no existe una investigación sin síntoma (ADR 0004) ---
if bash "$SCRIPT" init 2>/dev/null; then
  echo "TEST FAIL: 'init' sin síntoma debería fallar — no puede existir una investigación sin síntoma registrado." >&2
  exit 1
fi
echo "PASS: 'init' sin síntoma es rechazado."

if bash "$SCRIPT" init "" 2>/dev/null; then
  echo "TEST FAIL: 'init' con síntoma vacío debería fallar." >&2
  exit 1
fi
echo "PASS: 'init' con síntoma vacío es rechazado."

if bash "$SCRIPT" init "sintoma" "extra" 2>/dev/null; then
  echo "TEST FAIL: 'init' con dos argumentos debería fallar (solo acepta el síntoma)." >&2
  exit 1
fi
echo "PASS: 'init' con más de un argumento es rechazado."

# --- init es atómico bajo concurrencia: N inits en paralelo, N ids únicos ---
N=15
ids_file="$TMP_DIR/ids-concurrentes.txt"
: > "$ids_file"
pids=()
for _ in $(seq 1 "$N"); do
  (bash "$SCRIPT" init "sintoma concurrente" >> "$ids_file") &
  pids+=($!)
done
for pid in "${pids[@]}"; do
  wait "$pid"
done

if [ "$(wc -l < "$ids_file")" -ne "$N" ]; then
  echo "TEST FAIL: se esperaban $N ids de $N inits concurrentes, hubo $(wc -l < "$ids_file")." >&2
  exit 1
fi
if [ "$(sort -u "$ids_file" | wc -l)" -ne "$N" ]; then
  echo "TEST FAIL: $N inits concurrentes deberían generar $N ids únicos (el lock evita colisiones). Ids obtenidos:" >&2
  cat "$ids_file" >&2
  exit 1
fi
echo "PASS: $N inits concurrentes en el mismo proyecto generan $N ids únicos (sin colisiones)."

# El contador siguió avanzando desde INV002: la próxima debería ser INV018.
id_post_concurrencia=$(bash "$SCRIPT" init "sintoma post concurrencia")
if [ "$id_post_concurrencia" != "INV018" ]; then
  echo "TEST FAIL: tras 2 + $N inits, el siguiente debería ser 'INV018', fue '$id_post_concurrencia'." >&2
  exit 1
fi
echo "PASS: el contador persiste correctamente el total tras la concurrencia."

# --- dir falla si no existe ---
if bash "$SCRIPT" dir "INV999" 2>/dev/null; then
  echo "TEST FAIL: 'dir' sobre un diagnóstico inexistente debería fallar." >&2
  exit 1
fi
echo "PASS: 'dir' falla para un diagnóstico que no fue inicializado."

# --- dir invocado DIRECTO (no anidado desde otra función) funciona ---
# Regresión: 'local id="$1" dir="$ROOT/$id"' en una sola línea expande
# $id antes de que la asignación surta efecto: funcionaba por casualidad
# cuando se llamaba desde otra función con un $id local del mismo
# nombre, pero fallaba con "unbound variable" al invocarse directo.
dir_directo=$(bash "$SCRIPT" dir "$id")
if [ "$dir_directo" != "$dir" ]; then
  echo "TEST FAIL: 'dir' invocado directo devolvió '$dir_directo', se esperaba '$dir'." >&2
  exit 1
fi
echo "PASS: 'dir' invocado directo (sin anidar) devuelve la ruta correcta."

# --- ruta-fase apunta dentro de fases/ ---
ruta=$(bash "$SCRIPT" ruta-fase "$id" "construir-bucle")
if [ "$ruta" != "$dir/fases/construir-bucle.md" ]; then
  echo "TEST FAIL: ruta-fase devolvió '$ruta', se esperaba '$dir/fases/construir-bucle.md'." >&2
  exit 1
fi
echo "PASS: ruta-fase devuelve la ruta esperada dentro de fases/."

# --- acumular agrega el contenido y falla si se repite ---
printf 'Contenido de la fase.\n' > "$dir/fases/construir-bucle.md"
bash "$SCRIPT" acumular "$id" "construir-bucle" "Fase: Construir bucle" >/dev/null
if ! grep -q "## Fase: Construir bucle" "$dir/DIAGNOSTICO.md" || ! grep -q "Contenido de la fase." "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: acumular no agregó el contenido esperado a DIAGNOSTICO.md." >&2
  exit 1
fi
echo "PASS: acumular agrega el contenido de la fase bajo su título."

if bash "$SCRIPT" acumular "$id" "construir-bucle" "Fase: Construir bucle" 2>/dev/null; then
  echo "TEST FAIL: acumular la misma fase dos veces debería fallar (evita duplicados)." >&2
  exit 1
fi
echo "PASS: acumular la misma fase dos veces falla, no duplica."

# --- dos proyectos distintos tienen contadores independientes ---
REPO_B="$TMP_DIR/proyecto-b"
mkdir -p "$REPO_B"
git -C "$REPO_B" init -q
git -C "$REPO_B" remote add origin "https://github.com/ivanlynch/proyecto-b.git"
cd "$REPO_B"

id_b=$(bash "$SCRIPT" init "síntoma del proyecto B")
if [ "$id_b" != "INV001" ]; then
  echo "TEST FAIL: el contador de un proyecto nuevo debería arrancar en 'INV001' sin importar cuánto avanzó el de otro proyecto, fue '$id_b'." >&2
  exit 1
fi
dir_b=$(bash "$SCRIPT" dir "$id_b")
if [ "$dir_b" = "$dir" ]; then
  echo "TEST FAIL: el mismo id ('INV001') en dos proyectos distintos no debería resolver a la misma carpeta." >&2
  exit 1
fi
if grep -q "contenido previo" "$dir_b/DIAGNOSTICO.md" 2>/dev/null; then
  echo "TEST FAIL: el diagnóstico del proyecto B no debería ver contenido del proyecto A." >&2
  exit 1
fi
echo "PASS: cada proyecto tiene su propio contador independiente, sin mezclarse."

# --- init sin origin y sin commits: el aviso queda grabado en DIAGNOSTICO.md, no solo en stderr ---
REPO_SIN_ORIGIN="$TMP_DIR/proyecto-sin-origin"
mkdir -p "$REPO_SIN_ORIGIN"
git -C "$REPO_SIN_ORIGIN" init -q
cd "$REPO_SIN_ORIGIN"

id_sin_origin=$(bash "$SCRIPT" init "algo se rompe en este repo sin origin" 2>/dev/null)
dir_sin_origin=$(bash "$SCRIPT" dir "$id_sin_origin")
if ! grep -qi "no se encontró un remoto" "$dir_sin_origin/DIAGNOSTICO.md"; then
  echo "TEST FAIL: sin origin ni commits, DIAGNOSTICO.md debería grabar el aviso de identidad degradada." >&2
  cat "$dir_sin_origin/DIAGNOSTICO.md" >&2
  exit 1
fi
echo "PASS: 'init' sin origin ni commits graba el aviso de identidad degradada en DIAGNOSTICO.md."

# --- init <sintoma con saltos de línea>: se colapsa a una sola línea ---
REPO_F="$TMP_DIR/proyecto-f"
mkdir -p "$REPO_F"
git -C "$REPO_F" init -q
git -C "$REPO_F" remote add origin "https://github.com/ivanlynch/proyecto-f.git"
cd "$REPO_F"

id_f=$(bash "$SCRIPT" init "$(printf 'primera línea\nsegunda línea')")
dir_f=$(bash "$SCRIPT" dir "$id_f")
if ! grep -q "^SINTOMA_USUARIO: primera línea segunda línea$" "$dir_f/DIAGNOSTICO.md"; then
  echo "TEST FAIL: un síntoma con saltos de línea debería colapsarse a una sola línea en la cabecera." >&2
  cat "$dir_f/DIAGNOSTICO.md" >&2
  exit 1
fi
echo "PASS: un síntoma con saltos de línea se colapsa a una sola línea (formato CAMPO: valor)."

echo "Todos los tests de estado.sh pasaron."
