#!/usr/bin/env bash
set -euo pipefail
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export INVESTIGACIONES_ROOT="$test_root/research"
script=$(cd "$(dirname "$0")/../.." && pwd)/scripts/crear-estructura-investigacion.sh
result=$($script caso-login-001)
[[ -f "$result/investigacion.md" ]]
[[ -f "$result/metadata/manifest.tsv" ]]
[[ -d "$result/evidencia" && -d "$result/reproduccion" ]]
if $script caso-login-001 >/dev/null 2>&1; then exit 1; fi
if $script 'Caso-Invalido' >/dev/null 2>&1; then exit 1; fi
echo OK
