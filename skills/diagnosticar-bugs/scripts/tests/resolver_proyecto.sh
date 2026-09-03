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
case "$slug" in
  github.com-ivanlynch-mi-repo-????????) ;;
  *) echo "TEST FAIL: slug esperado con forma 'github.com-ivanlynch-mi-repo-<8 hex>', obtenido '$slug'." >&2; exit 1 ;;
esac
echo "PASS: el slug sanitiza las barras a guiones y agrega un sufijo hash de 8 chars."

slug2=$("$TARGET_SCRIPT" slug "$REPO_HTTPS")
if [ "$slug" != "$slug2" ]; then
  echo "TEST FAIL: el slug debería ser determinista (mismo repo -> mismo slug siempre). '$slug' != '$slug2'" >&2
  exit 1
fi
echo "PASS: el slug es determinista para el mismo proyecto."

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

# --- sin remoto: cae a la ruta local, avisa por stderr, no aborta ---
REPO_SIN_REMOTO="${TMP_DIR}/repo-sin-remoto"
mkdir -p "$REPO_SIN_REMOTO"
git -C "$REPO_SIN_REMOTO" init -q
RUTA_REAL=$(cd -P "$REPO_SIN_REMOTO" && pwd)

STDERR_FILE="${TMP_DIR}/stderr.txt"
id_fallback=$("$TARGET_SCRIPT" identificador "$REPO_SIN_REMOTO" 2>"$STDERR_FILE")
if [ "$id_fallback" != "$RUTA_REAL" ]; then
  echo "TEST FAIL: sin remoto, se esperaba la ruta local '$RUTA_REAL', se obtuvo '$id_fallback'." >&2
  exit 1
fi
if ! grep -qi "no se encontró un remoto" "$STDERR_FILE"; then
  echo "TEST FAIL: sin remoto debería avisar por stderr." >&2
  exit 1
fi
echo "PASS: sin remoto, usa la ruta local y avisa por stderr sin abortar."

# --- repo con nombre gigante: el slug queda acotado, no crece sin límite ---
REPO_GIGANTE="${TMP_DIR}/repo-gigante"
mkdir -p "$REPO_GIGANTE"
git -C "$REPO_GIGANTE" init -q
git -C "$REPO_GIGANTE" remote add origin "https://gitlab.com/empresa/equipo-de-plataforma/proyectos-internos/servicio-de-facturacion-legacy-con-nombre-todavia-mas-largo.git"

slug_gigante=$("$TARGET_SCRIPT" slug "$REPO_GIGANTE")
if [ "${#slug_gigante}" -gt 70 ]; then
  echo "TEST FAIL: el slug de un repo con nombre gigante no debería superar ~70 caracteres, tiene ${#slug_gigante}: '$slug_gigante'" >&2
  exit 1
fi
echo "PASS: un repo con nombre gigante da un slug acotado (${#slug_gigante} caracteres)."

# --- dos repos que truncan al mismo prefijo de 60 chars no colisionan ---
REPO_LARGO_A="${TMP_DIR}/repo-largo-a"
mkdir -p "$REPO_LARGO_A"
git -C "$REPO_LARGO_A" init -q
git -C "$REPO_LARGO_A" remote add origin "https://gitlab.com/organizacion-con-nombre-particularmente-largo-de-verdad/proyecto-a.git"

REPO_LARGO_B="${TMP_DIR}/repo-largo-b"
mkdir -p "$REPO_LARGO_B"
git -C "$REPO_LARGO_B" init -q
git -C "$REPO_LARGO_B" remote add origin "https://gitlab.com/organizacion-con-nombre-particularmente-largo-de-verdad/proyecto-b.git"

slug_largo_a=$("$TARGET_SCRIPT" slug "$REPO_LARGO_A")
slug_largo_b=$("$TARGET_SCRIPT" slug "$REPO_LARGO_B")
prefijo_a="${slug_largo_a%-????????}"
prefijo_b="${slug_largo_b%-????????}"
if [ "$prefijo_a" != "$prefijo_b" ]; then
  echo "AVISO: este test asumía que los prefijos truncados coincidían para forzar el caso de colisión; no coincidieron ('$prefijo_a' vs '$prefijo_b'), pero igual verificamos que los slugs completos difieran." >&2
fi
if [ "$slug_largo_a" = "$slug_largo_b" ]; then
  echo "TEST FAIL: dos proyectos distintos con el mismo prefijo truncado no deberían terminar con el mismo slug." >&2
  exit 1
fi
echo "PASS: dos proyectos que truncan al mismo prefijo no colisionan (el hash sale del identificador completo)."

echo "Todos los tests de resolver_proyecto.sh pasaron."
