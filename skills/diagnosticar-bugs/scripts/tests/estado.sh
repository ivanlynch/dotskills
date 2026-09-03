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

# --- init crea la carpeta anidada por proyecto y DIAGNOSTICO.md ---
dir=$(bash "$SCRIPT" init "export-timeout-500")
if [ ! -d "$dir" ] || [ ! -f "$dir/DIAGNOSTICO.md" ] || [ ! -d "$dir/fases" ]; then
  echo "TEST FAIL: init no creó la estructura esperada." >&2
  exit 1
fi
case "$dir" in
  "$DIAGNOSTICOS_ROOT"/[0-9a-f][0-9a-f]*/export-timeout-500)
    slug_generado="${dir#"$DIAGNOSTICOS_ROOT"/}"
    slug_generado="${slug_generado%/export-timeout-500}"
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

# --- init es idempotente (no pisa un diagnóstico existente) ---
echo "contenido previo" >> "$dir/DIAGNOSTICO.md"
dir2=$(bash "$SCRIPT" init "export-timeout-500")
if [ "$dir2" != "$dir" ] || ! grep -q "contenido previo" "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: un segundo init no debería pisar el diagnóstico existente." >&2
  exit 1
fi
echo "PASS: init no pisa un diagnóstico ya creado."

# --- id inválido falla ---
if bash "$SCRIPT" init "ID CON ESPACIOS" 2>/dev/null; then
  echo "TEST FAIL: un id inválido debería fallar." >&2
  exit 1
fi
echo "PASS: un id inválido (mayúsculas/espacios) es rechazado."

# --- dir falla si no existe ---
if bash "$SCRIPT" dir "no-existe-este" 2>/dev/null; then
  echo "TEST FAIL: 'dir' sobre un diagnóstico inexistente debería fallar." >&2
  exit 1
fi
echo "PASS: 'dir' falla para un diagnóstico que no fue inicializado."

# --- dir invocado DIRECTO (no anidado desde otra función) funciona ---
# Regresión: 'local id="$1" dir="$ROOT/$id"' en una sola línea expande
# $id antes de que la asignación surta efecto: funcionaba por casualidad
# cuando se llamaba desde otra función con un $id local del mismo
# nombre, pero fallaba con "unbound variable" al invocarse directo.
dir_directo=$(bash "$SCRIPT" dir "export-timeout-500")
if [ "$dir_directo" != "$dir" ]; then
  echo "TEST FAIL: 'dir' invocado directo devolvió '$dir_directo', se esperaba '$dir'." >&2
  exit 1
fi
echo "PASS: 'dir' invocado directo (sin anidar) devuelve la ruta correcta."

# --- ruta-fase apunta dentro de fases/ ---
ruta=$(bash "$SCRIPT" ruta-fase "export-timeout-500" "construir-bucle")
if [ "$ruta" != "$dir/fases/construir-bucle.md" ]; then
  echo "TEST FAIL: ruta-fase devolvió '$ruta', se esperaba '$dir/fases/construir-bucle.md'." >&2
  exit 1
fi
echo "PASS: ruta-fase devuelve la ruta esperada dentro de fases/."

# --- acumular agrega el contenido y falla si se repite ---
printf 'Contenido de la fase.\n' > "$dir/fases/construir-bucle.md"
bash "$SCRIPT" acumular "export-timeout-500" "construir-bucle" "Fase: Construir bucle" >/dev/null
if ! grep -q "## Fase: Construir bucle" "$dir/DIAGNOSTICO.md" || ! grep -q "Contenido de la fase." "$dir/DIAGNOSTICO.md"; then
  echo "TEST FAIL: acumular no agregó el contenido esperado a DIAGNOSTICO.md." >&2
  exit 1
fi
echo "PASS: acumular agrega el contenido de la fase bajo su título."

if bash "$SCRIPT" acumular "export-timeout-500" "construir-bucle" "Fase: Construir bucle" 2>/dev/null; then
  echo "TEST FAIL: acumular la misma fase dos veces debería fallar (evita duplicados)." >&2
  exit 1
fi
echo "PASS: acumular la misma fase dos veces falla, no duplica."

# --- dos proyectos distintos, mismo id de diagnóstico: no se mezclan ---
REPO_B="$TMP_DIR/proyecto-b"
mkdir -p "$REPO_B"
git -C "$REPO_B" init -q
git -C "$REPO_B" remote add origin "https://github.com/ivanlynch/proyecto-b.git"
cd "$REPO_B"

dir_b=$(bash "$SCRIPT" init "export-timeout-500")
if [ "$dir_b" = "$dir" ]; then
  echo "TEST FAIL: el mismo id de diagnóstico en dos proyectos distintos no debería resolver a la misma carpeta." >&2
  exit 1
fi
if [ -f "$dir_b/DIAGNOSTICO.md" ] && grep -q "contenido previo" "$dir_b/DIAGNOSTICO.md"; then
  echo "TEST FAIL: el diagnóstico del proyecto B no debería ver contenido del proyecto A." >&2
  exit 1
fi
echo "PASS: dos proyectos con el mismo id de diagnóstico quedan en carpetas separadas, sin mezclarse."

echo "Todos los tests de estado.sh pasaron."
