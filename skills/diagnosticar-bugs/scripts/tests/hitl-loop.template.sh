#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/hitl-loop.template.sh"

[[ -x "$script" ]] || { echo "El script no es ejecutable: $script" >&2; exit 1; }
bash -n "$script"
grep -Fq 'set -euo pipefail' "$script"
grep -Fq 'printf '\''ERROR=%s\\n'\'' "$ERROR"' "$script"
grep -Fq 'printf '\''MENSAJE_ERROR=%s\\n'\'' "$MENSAJE_ERROR"' "$script"

echo "OK: hitl-loop.template.sh tiene sintaxis válida y emite las variables capturadas"
