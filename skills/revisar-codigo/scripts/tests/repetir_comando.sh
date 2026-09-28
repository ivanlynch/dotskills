#!/usr/bin/env bash
set -euo pipefail

# Bash-only tests for repetir_comando.sh.
# Dependencies: bash, jq, mktemp and standard POSIX utilities.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../repetir_comando.sh"

assert_status() {
  local expected="$1"
  shift
  set +e
  "$@" >/dev/null 2>/dev/null
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || {
    echo "Se esperaba exit code $expected, se obtuvo $actual" >&2
    exit 1
  }
}

assert_status 2 bash "$SCRIPT"
assert_status 2 bash "$SCRIPT" /directorio/inexistente -- printf hola

fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT

stable="$(bash "$SCRIPT" "$fixture_dir" -- bash -c 'printf "fallo estable\n"; exit 7')"
printf '%s' "$stable" | jq -e '
  .executions[0].exit_code == 7 and
  .executions[1].exit_code == 7 and
  .same_exit_code == true and
  .same_output == true and
  .byte_identical == true
' >/dev/null
stable_result_dir="$(printf '%s' "$stable" | jq -r '.result_directory')"
rm -rf "$stable_result_dir"

counter_script="$fixture_dir/counter.sh"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'value=0' \
  '[[ -f "$1" ]] && value="$(cat "$1")"' \
  'value=$((value + 1))' \
  'printf "%s" "$value" >"$1"' \
  'printf "%s\n" "$value"' >"$counter_script"
chmod +x "$counter_script"

unstable="$(bash "$SCRIPT" "$fixture_dir" -- bash "$counter_script" "$fixture_dir/count")"
printf '%s' "$unstable" | jq -e '
  .same_exit_code == true and
  .same_output == false and
  .byte_identical == false
' >/dev/null
unstable_result_dir="$(printf '%s' "$unstable" | jq -r '.result_directory')"
rm -rf "$unstable_result_dir"

relative_script="$fixture_dir/relative.sh"
printf '%s\n' '#!/usr/bin/env bash' 'printf "ruta relativa\n"' >"$relative_script"
chmod +x "$relative_script"
relative="$(bash "$SCRIPT" "$fixture_dir" -- ./relative.sh)"
printf '%s' "$relative" | jq -e '.byte_identical == true' >/dev/null
relative_result_dir="$(printf '%s' "$relative" | jq -r '.result_directory')"
rm -rf "$relative_result_dir"

echo "OK: repetición estable e inestable"
