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
id=$(bash "$SCRIPT" init)
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
   || ! grep -qE "^Commit:   [0-9a-f]+$" "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: DIAGNOSTICO.md debería grabar proyecto, branch y commit al momento del init." >&2
  cat "$dir/DIAGNOSTICO.md" >&2
  exit 1
fi
echo "PASS: init graba proyecto, branch y commit en DIAGNOSTICO.md."

# --- init NO es idempotente: cada llamada arranca una investigación nueva ---
echo "contenido previo" >> "$dir/DIAGNOSTICO.md"
id2=$(bash "$SCRIPT" init)
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

# --- init ya no acepta argumentos (la interfaz vieja pasaba un <id>) ---
if bash "$SCRIPT" init "export-timeout-500" 2>/dev/null; then
  echo "TEST FAIL: 'init' con un argumento debería fallar (ya no recibe un id manual)." >&2
  exit 1
fi
echo "PASS: 'init' con un argumento (interfaz vieja) es rechazado."

# --- init es atómico bajo concurrencia: N inits en paralelo, N ids únicos ---
N=15
ids_file="$TMP_DIR/ids-concurrentes.txt"
: > "$ids_file"
pids=()
for _ in $(seq 1 "$N"); do
  (bash "$SCRIPT" init >> "$ids_file") &
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
id_post_concurrencia=$(bash "$SCRIPT" init)
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

id_b=$(bash "$SCRIPT" init)
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

# --- listar: proyecto sin investigaciones todavía -> vacío, sin error ---
REPO_C="$TMP_DIR/proyecto-c"
mkdir -p "$REPO_C"
git -C "$REPO_C" init -q
git -C "$REPO_C" remote add origin "https://github.com/ivanlynch/proyecto-c.git"
cd "$REPO_C"

listado_vacio=$(bash "$SCRIPT" listar)
if [ -n "$listado_vacio" ]; then
  echo "TEST FAIL: 'listar' en un proyecto sin investigaciones debería estar vacío, fue: '$listado_vacio'." >&2
  exit 1
fi
echo "PASS: 'listar' en un proyecto sin investigaciones no imprime nada (y no falla)."

# --- listar: por default, solo las que tienen SINTOMA_USUARIO acumulado ---
id_c1=$(bash "$SCRIPT" init)
dir_c1=$(bash "$SCRIPT" dir "$id_c1")
printf '\n## Fase: Construir bucle de feedback\n\nSINTOMA_USUARIO: el export tarda 500ms de más\nMETODO: cli_fixture\n' >> "$dir_c1/DIAGNOSTICO.md"

id_c2=$(bash "$SCRIPT" init)

listado=$(bash "$SCRIPT" listar)
esperado="$(printf '%s\t%s' "$id_c1" "el export tarda 500ms de más")"
if [ "$listado" != "$esperado" ]; then
  echo "TEST FAIL: 'listar' sin flags no devolvió lo esperado (debería omitir '$id_c2', sin síntoma todavía)." >&2
  echo "--- esperado ---" >&2
  printf '%s\n' "$esperado" >&2
  echo "--- obtenido ---" >&2
  printf '%s\n' "$listado" >&2
  exit 1
fi
echo "PASS: 'listar' sin flags omite las investigaciones sin síntoma acumulado."

# --- listar --todas: también muestra las que no tienen síntoma ---
listado_todas=$(bash "$SCRIPT" listar --todas)
esperado_todas="$(printf '%s\t%s\n%s\t%s' "$id_c1" "el export tarda 500ms de más" "$id_c2" "(sin síntoma registrado todavía)")"
if [ "$listado_todas" != "$esperado_todas" ]; then
  echo "TEST FAIL: 'listar --todas' no devolvió lo esperado." >&2
  echo "--- esperado ---" >&2
  printf '%s\n' "$esperado_todas" >&2
  echo "--- obtenido ---" >&2
  printf '%s\n' "$listado_todas" >&2
  exit 1
fi
echo "PASS: 'listar --todas' incluye también las investigaciones sin síntoma, con el aviso correspondiente."

# --- listar: una opción desconocida falla en vez de ignorarse en silencio ---
if bash "$SCRIPT" listar --raro 2>/dev/null; then
  echo "TEST FAIL: 'listar' con una opción desconocida debería fallar." >&2
  exit 1
fi
echo "PASS: 'listar' con una opción desconocida falla en vez de ignorarla."

echo "Todos los tests de estado.sh pasaron."
