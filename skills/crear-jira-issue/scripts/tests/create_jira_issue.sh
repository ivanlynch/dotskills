#!/usr/bin/env bash
set -euo pipefail

# Bash-only smoke tests. The API call uses a fake curl executable.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../create_jira_issue.sh"

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
assert_status 6 bash "$SCRIPT" --title-file /tmp/missing-title --description-file /tmp/missing-description
assert_status 2 env -u JIRA_BASE_URL -u JIRA_EMAIL -u JIRA_API_TOKEN bash "$SCRIPT" --title-file "$SCRIPT" --description-file "$SCRIPT"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
printf '%s\n' 'Título de prueba' > "$tmp_dir/title.txt"
printf '%s\n' 'Descripción de prueba' > "$tmp_dir/description.md"
printf '%s\n' '#!/usr/bin/env bash' 'while [[ "$1" != "--output" ]]; do shift; done' 'shift' 'output="$1"' 'printf "%s" '\''{"key":"DTCZE-14436","id":"123456"}'\'' > "$output"' 'printf "201"' > "$tmp_dir/curl"
chmod +x "$tmp_dir/curl"
result="$(PATH="$tmp_dir:$PATH" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md")"
printf '%s' "$result" | jq -e '.issue_key == "DTCZE-14436" and .parent == "DTCZE-12424" and .project == "DTCZE" and .issue_type == "Sub-task" and .url == "https://jira.example/browse/DTCZE-14436"' >/dev/null

echo "OK: validación de argumentos, autenticación y creación simulada"

