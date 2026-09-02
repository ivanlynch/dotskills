#!/usr/bin/env bash
set -euo pipefail
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export INVESTIGACIONES_ROOT="$test_root/research"
base=$(cd "$(dirname "$0")/../.." && pwd)
id=caso-login-003
"$base/scripts/crear-estructura-investigacion.sh" "$id" >/dev/null
printf 'La API devuelve timeout; debería responder en menos de un segundo.\n' | "$base/scripts/registrar-respuesta.sh" --investigacion "$id" --seccion sintoma --texto-stdin >/dev/null
grep -Fq 'La API devuelve timeout' "$test_root/research/$id/investigacion.md"
grep -Fq $'\tsintoma\t' "$test_root/research/$id/metadata/respuestas.log"
if printf 'otra respuesta\n' | "$base/scripts/registrar-respuesta.sh" --investigacion "$id" --seccion sintoma --texto-stdin >/dev/null 2>&1; then exit 1; fi
echo OK
