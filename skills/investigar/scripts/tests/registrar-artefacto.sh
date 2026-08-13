#!/usr/bin/env bash
set -euo pipefail
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export INVESTIGACIONES_ROOT="$test_root/research"
base=$(cd "$(dirname "$0")/../.." && pwd)
id=caso-login-002
"$base/scripts/crear-estructura-investigacion.sh" "$id" >/dev/null
printf 'stack trace redactado\n' > "$test_root/input.txt"
result=$("$base/scripts/registrar-artefacto.sh" --investigacion "$id" --tipo evidencia --descripcion 'Stack trace' --archivo "$test_root/input.txt" --redactado)
artifact=$(printf '%s\n' "$result" | awk '{print $2}')
[[ -f "$test_root/research/$id/$artifact" ]]
[[ $(wc -l < "$test_root/research/$id/metadata/manifest.tsv") -eq 2 ]]
if "$base/scripts/registrar-artefacto.sh" --investigacion "$id" --tipo evidencia --descripcion 'No redactado' --archivo "$test_root/input.txt" >/dev/null 2>&1; then exit 1; fi
echo OK
