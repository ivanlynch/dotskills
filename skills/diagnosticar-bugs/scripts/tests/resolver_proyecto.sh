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

echo "Todos los tests de resolver_proyecto.sh pasaron."
