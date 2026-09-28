#!/usr/bin/env bash
set -euo pipefail

# Bash-only tests for preparar_revision.sh. GitHub and Git are simulated.
# Dependencies: bash, jq, mktemp and standard POSIX utilities.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../preparar_revision.sh"

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
assert_status 2 bash "$SCRIPT" abc

fixture_dir="$(mktemp -d)"
fake_bin="$fixture_dir/bin"
mkdir -p "$fake_bin"
trap 'rm -rf "$fixture_dir"' EXIT

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'cat <<JSON' \
  '{"number":42,"url":"https://github.example/pr/42","state":"OPEN","title":"Cambio","baseRefName":"main","baseRefOid":"1111111111111111111111111111111111111111","headRefName":"'"'"'${FAKE_HEAD_REF:-feat/DTCZE-1234-cambio}'"'"'","headRefOid":"2222222222222222222222222222222222222222"}' \
  'JSON' >"$fake_bin/gh"
chmod +x "$fake_bin/gh"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  rev-parse) printf "%s\n" /fake/repo ;;' \
  '  cat-file) exit 0 ;;' \
  '  merge-base) printf "%s\n" 3333333333333333333333333333333333333333 ;;' \
  '  diff)' \
  '    if [[ "$2" == "--quiet" ]]; then exit 1; fi' \
  '    if [[ "${FAKE_LARGE:-0}" == "1" ]]; then' \
  '      i=0; while [[ "$i" -lt 51 ]]; do printf "60\\t0\\tf%s\\n" "$i"; i=$((i + 1)); done' \
  '    else' \
  '      printf "10\\t2\\tsrc/a.ts\\n5\\t1\\tsrc/b.ts\\n"' \
  '    fi' \
  '    ;;' \
  '  log) printf "abc123\\tfeat: cambio\\n" ;;' \
  '  remote) printf "%s\\n" https://github.example/repo.git ;;' \
  '  fetch) exit 0 ;;' \
  '  *) printf "git simulado: argumentos inesperados: %s\\n" "$*" >&2; exit 99 ;;' \
  'esac' >"$fake_bin/git"
chmod +x "$fake_bin/git"

result="$(PATH="$fake_bin:$PATH" bash "$SCRIPT" 42)"
printf '%s' "$result" | jq -e '
  .pr.number == 42 and
  .merge_base == "3333333333333333333333333333333333333333" and
  .ticket_ids == ["DTCZE-1234"] and
  .ticket_resolution == "resolved" and
  .diff.files == 2 and
  .diff.changed_lines == 18 and
  .diff.oversized == false
' >/dev/null

missing="$(PATH="$fake_bin:$PATH" FAKE_HEAD_REF=feat/sin-ticket bash "$SCRIPT" 42)"
printf '%s' "$missing" | jq -e '.ticket_ids == [] and .ticket_resolution == "missing"' >/dev/null

ambiguous="$(PATH="$fake_bin:$PATH" FAKE_HEAD_REF=feat/DTCZE-1234-DTCZE-5678 bash "$SCRIPT" 42)"
printf '%s' "$ambiguous" | jq -e '.ticket_ids | sort == ["DTCZE-1234", "DTCZE-5678"]' >/dev/null
printf '%s' "$ambiguous" | jq -e '.ticket_resolution == "ambiguous"' >/dev/null

large="$(PATH="$fake_bin:$PATH" FAKE_LARGE=1 bash "$SCRIPT" 42)"
printf '%s' "$large" | jq -e '.diff.files == 51 and .diff.changed_lines == 3060 and .diff.oversized == true' >/dev/null

echo "OK: preparación de PR, tickets y límites"
