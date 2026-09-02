#!/usr/bin/env bash
set -euo pipefail

# Bash-only smoke tests. Jira requests use a fake curl executable.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../transition_ready_for_prod.sh"

assert_status() {
  local expected="$1"
  shift
  set +e
  "$@" >/dev/null 2>/dev/null
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || { echo "Se esperaba exit code $expected, se obtuvo $actual" >&2; exit 1; }
}

assert_status 6 bash "$SCRIPT"
assert_status 6 bash "$SCRIPT" invalid
assert_status 2 env -u JIRA_BASE_URL -u JIRA_EMAIL -u JIRA_API_TOKEN bash "$SCRIPT" DTCZE-14435

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
printf '%s' '0' > "$tmp_dir/count"
printf '%s\n' '#!/usr/bin/env bash' 'while [[ "$1" != "--output" ]]; do shift; done' 'shift' 'output="$1"' 'count=$(cat "$FAKE_CURL_COUNT")' 'count=$((count + 1))' 'printf "%s" "$count" > "$FAKE_CURL_COUNT"' 'case "$count" in 1) printf "%s" '\''{"values":[{"id":123,"name":"Sprint 42","state":"active"}]}'\'' > "$output"; printf "200" ;; 2) printf "%s" '\''{}'\'' > "$output"; printf "204" ;; 3) printf "%s" '\''{"transitions":[{"id":"31","name":"Ready for Prod"},{"id":"41","name":"Done"}]}'\'' > "$output"; printf "200" ;; *) printf "%s" '\''{}'\'' > "$output"; printf "204" ;; esac' > "$tmp_dir/curl"
chmod +x "$tmp_dir/curl"
result="$(PATH="$tmp_dir:$PATH" FAKE_CURL_COUNT="$tmp_dir/count" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" dtcze-14435)"
printf '%s' "$result" | jq -e '.ticket_id == "DTCZE-14435" and .board_id == "54142" and .sprint_id == "123" and .sprint_name == "Sprint 42" and .transition == "Ready for Prod" and .status == "Ready for Prod"' >/dev/null

echo "OK: validación de argumentos, autenticación y transición simulada"
