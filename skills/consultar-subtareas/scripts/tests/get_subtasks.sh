#!/usr/bin/env bash
set -euo pipefail

# Bash-only smoke tests for get_subtasks.sh. The API call is not made.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../get_subtasks.sh"

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

assert_status 4 bash "$SCRIPT"
assert_status 4 bash "$SCRIPT" invalid
assert_status 2 env -u JIRA_BASE_URL -u JIRA_EMAIL -u JIRA_API_TOKEN bash "$SCRIPT" DTCZE-1234

fake_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin"' EXIT
printf '%s\n' '#!/usr/bin/env bash' 'while [[ "$1" != "--output" ]]; do shift; done' 'shift' 'output="$1"' 'printf "%s" '\''{"fields":{"subtasks":[{"key":"DTCZE-1235","fields":{"summary":"Implementar"}}]}}'\'' > "$output"' 'printf "200"' > "$fake_bin/curl"
chmod +x "$fake_bin/curl"
result="$(PATH="$fake_bin:$PATH" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" dtcze-1234)"
printf '%s' "$result" | jq -e '.ticket_id == "DTCZE-1234" and .subtasks[0].ticket_id == "DTCZE-1235" and .subtasks[0].title == "Implementar"' >/dev/null

echo "OK: validación de argumentos y autenticación"
