#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/../resolver_proyecto.sh"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Ejecutando tests para resolver_proyecto.sh..."

# --- repo con remoto HTTPS ---
REPO_HTTPS="${TMP_DIR}/repo-https"
mkdir -p "$REPO_HTTPS"
git -C "$REPO_HTTPS" init -q
git -C "$REPO_HTTPS" remote add origin "https://github.com/ivanlynch/mi-repo.git"

id=$("$TARGET_SCRIPT" identificador "$REPO_HTTPS")
if [ "$id" != "github.com/ivanlynch/mi-repo" ]; then
  echo "TEST FAIL: identificador HTTPS esperado 'github.com/ivanlynch/mi-repo', obtenido '$id'." >&2
  exit 1
fi
echo "PASS: normaliza un remoto HTTPS."

slug=$("$TARGET_SCRIPT" slug "$REPO_HTTPS")
if ! [[ "$slug" =~ ^[0-9a-f]{64}$ ]]; then
  echo "TEST FAIL: el slug debería ser sha256 en hex (64 caracteres, 0-9a-f), obtenido '$slug' (${#slug} caracteres)." >&2
  exit 1
fi
echo "PASS: el slug es sha256(identificador) en hex, siempre 64 caracteres."

slug2=$("$TARGET_SCRIPT" slug "$REPO_HTTPS")
if [ "$slug" != "$slug2" ]; then
  echo "TEST FAIL: el slug debería ser determinista (mismo repo -> mismo slug siempre). '$slug' != '$slug2'" >&2
  exit 1
fi
echo "PASS: el slug es determinista para el mismo proyecto."

# --- slug-de: hashea un identificador arbitrario, sin resolverlo desde un dir ---
slug_de_directo=$("$TARGET_SCRIPT" slug-de "github.com/ivanlynch/mi-repo")
if [ "$slug_de_directo" != "$slug" ]; then
  echo "TEST FAIL: 'slug-de <identificador>' debería dar el mismo slug que 'slug <dir>' para el identificador equivalente. '$slug_de_directo' != '$slug'" >&2
  exit 1
fi
echo "PASS: 'slug-de <identificador>' da el mismo slug que 'slug <dir>' (usado por 'estado.sh migrar', ver issue #11)."

# --- repo con remoto SSH (formato scp) ---
REPO_SSH="${TMP_DIR}/repo-ssh"
mkdir -p "$REPO_SSH"
git -C "$REPO_SSH" init -q
git -C "$REPO_SSH" remote add origin "git@github.com:ivanlynch/otro-repo.git"

id=$("$TARGET_SCRIPT" identificador "$REPO_SSH")
if [ "$id" != "github.com/ivanlynch/otro-repo" ]; then
  echo "TEST FAIL: identificador SSH esperado 'github.com/ivanlynch/otro-repo', obtenido '$id'." >&2
  exit 1
fi
echo "PASS: normaliza un remoto SSH (formato scp)."

# --- dos proyectos distintos dan slugs distintos (no se mezclan) ---
slug_https=$("$TARGET_SCRIPT" slug "$REPO_HTTPS")
slug_ssh=$("$TARGET_SCRIPT" slug "$REPO_SSH")
if [ "$slug_https" = "$slug_ssh" ]; then
  echo "TEST FAIL: dos proyectos distintos no deberían compartir slug." >&2
  exit 1
fi
echo "PASS: proyectos distintos producen slugs distintos."

# --- sin remoto NI commits: último recurso, cae a la ruta local, avisa por stderr, no aborta ---
REPO_SIN_REMOTO="${TMP_DIR}/repo-sin-remoto"
mkdir -p "$REPO_SIN_REMOTO"
git -C "$REPO_SIN_REMOTO" init -q
RUTA_REAL=$(cd -P "$REPO_SIN_REMOTO" && pwd)

STDERR_FILE="${TMP_DIR}/stderr.txt"
id_fallback=$("$TARGET_SCRIPT" identificador "$REPO_SIN_REMOTO" 2>"$STDERR_FILE")
if [ "$id_fallback" != "$RUTA_REAL" ]; then
  echo "TEST FAIL: sin remoto ni commits, se esperaba la ruta local '$RUTA_REAL', se obtuvo '$id_fallback'." >&2
  exit 1
fi
if ! grep -qi "no se encontró un remoto" "$STDERR_FILE"; then
  echo "TEST FAIL: sin remoto ni commits debería avisar por stderr." >&2
  exit 1
fi
echo "PASS: sin remoto ni commits, usa la ruta local (último recurso) y avisa por stderr sin abortar."

# --- sin remoto, CON commits: usa el hash del commit raíz, no el path ---
REPO_SIN_REMOTO_CON_COMMIT="${TMP_DIR}/repo-sin-remoto-con-commit"
mkdir -p "$REPO_SIN_REMOTO_CON_COMMIT"
git -C "$REPO_SIN_REMOTO_CON_COMMIT" init -q
git -C "$REPO_SIN_REMOTO_CON_COMMIT" -c user.email=t@t.com -c user.name=T -c commit.gpgsign=false commit -q --allow-empty -m init

id_raiz=$("$TARGET_SCRIPT" identificador "$REPO_SIN_REMOTO_CON_COMMIT" 2>/dev/null)
raiz_esperada="sin-remoto:$(git -C "$REPO_SIN_REMOTO_CON_COMMIT" rev-list --max-parents=0 HEAD)"
if [ "$id_raiz" != "$raiz_esperada" ]; then
  echo "TEST FAIL: sin remoto pero con commits se esperaba '$raiz_esperada', se obtuvo '$id_raiz'." >&2
  exit 1
fi
echo "PASS: sin remoto pero con commits, usa 'sin-remoto:<hash del commit raíz>', no el path."

# --- mismo historial (mismo commit raíz), clonado en dos paths distintos -> mismo identificador ---
REPO_CLON="${TMP_DIR}/repo-sin-remoto-clon"
git clone -q "$REPO_SIN_REMOTO_CON_COMMIT" "$REPO_CLON"
git -C "$REPO_CLON" remote remove origin

id_original=$("$TARGET_SCRIPT" identificador "$REPO_SIN_REMOTO_CON_COMMIT" 2>/dev/null)
id_clon=$("$TARGET_SCRIPT" identificador "$REPO_CLON" 2>/dev/null)
if [ "$id_original" != "$id_clon" ]; then
  echo "TEST FAIL: el mismo historial en paths distintos debería dar el mismo identificador. '$id_original' != '$id_clon'" >&2
  exit 1
fi
echo "PASS: sin remoto, el mismo historial da el mismo identificador sin importar el path (a diferencia del fallback viejo)."

# --- repo con nombre gigante: el slug sigue siendo 64 chars igual ---
REPO_GIGANTE="${TMP_DIR}/repo-gigante"
mkdir -p "$REPO_GIGANTE"
git -C "$REPO_GIGANTE" init -q
git -C "$REPO_GIGANTE" remote add origin "https://gitlab.com/empresa/equipo-de-plataforma/proyectos-internos/servicio-de-facturacion-legacy-con-nombre-todavia-mas-largo.git"

slug_gigante=$("$TARGET_SCRIPT" slug "$REPO_GIGANTE")
if ! [[ "$slug_gigante" =~ ^[0-9a-f]{64}$ ]]; then
  echo "TEST FAIL: un repo con nombre gigante debería dar igual un slug de 64 chars, obtenido '$slug_gigante' (${#slug_gigante} caracteres)." >&2
  exit 1
fi
echo "PASS: un repo con nombre gigante da el mismo largo de slug que cualquier otro (64 caracteres)."

# --- submódulo: la identidad siempre queda linkeada al repo padre ---
SUB_LIB="${TMP_DIR}/sub-lib"
mkdir -p "$SUB_LIB"
git -C "$SUB_LIB" init -q
git -C "$SUB_LIB" -c user.email=t@t.com -c user.name=T -c commit.gpgsign=false commit -q --allow-empty -m init
git -C "$SUB_LIB" remote add origin "https://github.com/ivanlynch/sub-lib.git"

APP_PADRE="${TMP_DIR}/app-padre"
mkdir -p "$APP_PADRE"
git -C "$APP_PADRE" init -q
git -C "$APP_PADRE" -c user.email=t@t.com -c user.name=T -c commit.gpgsign=false commit -q --allow-empty -m init
git -C "$APP_PADRE" remote add origin "https://github.com/ivanlynch/app-padre.git"
git -C "$APP_PADRE" -c protocol.file.allow=always submodule add -q "$SUB_LIB" libs/sub-lib
git -C "$APP_PADRE" -c user.email=t@t.com -c user.name=T -c commit.gpgsign=false commit -q -m "agrega submodulo"

id_padre=$("$TARGET_SCRIPT" identificador "$APP_PADRE")
id_desde_submodulo=$("$TARGET_SCRIPT" identificador "${APP_PADRE}/libs/sub-lib")
if [ "$id_desde_submodulo" != "$id_padre" ]; then
  echo "TEST FAIL: parado dentro del submódulo, el identificador debería ser el del padre ('$id_padre'), fue '$id_desde_submodulo'." >&2
  exit 1
fi
if [ "$id_desde_submodulo" = "github.com/ivanlynch/sub-lib" ]; then
  echo "TEST FAIL: el identificador no debería ser el remoto propio del submódulo." >&2
  exit 1
fi
echo "PASS: parado dentro de un submódulo, la identidad queda linkeada al repo padre, no al submódulo."

# --- el mismo submódulo, clonado standalone (sin padre), usa su propio remoto ---
id_standalone=$("$TARGET_SCRIPT" identificador "$SUB_LIB")
if [ "$id_standalone" != "github.com/ivanlynch/sub-lib" ]; then
  echo "TEST FAIL: un repo que es submódulo EN OTRO LADO pero se clona standalone debería usar su propio remoto, fue '$id_standalone'." >&2
  exit 1
fi
echo "PASS: el mismo repo clonado standalone (sin superproyecto) sigue usando su propio remoto."

echo "Todos los tests de resolver_proyecto.sh pasaron."
