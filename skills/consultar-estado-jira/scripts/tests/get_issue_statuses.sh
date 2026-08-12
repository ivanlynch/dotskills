#!/usr/bin/env bash
set -euo pipefail

# Bash-only smoke tests for get_issue_statuses.sh. The API call is not made.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../get_issue_statuses.sh"

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

assert_status 1 bash "$SCRIPT"
assert_status 1 bash "$SCRIPT" invalid
assert_status 2 env -u JIRA_BASE_URL -u JIRA_EMAIL -u JIRA_API_TOKEN bash "$SCRIPT" DTCZE-14448

fake_bin="$(mktemp -d)"
trap 'rm -rf "$fake_bin"' EXIT
apply_fake_curl() {
  local target="$1"
  cat >"$target" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output=""
previous=""
for arg in "$@"; do
  if [[ "$previous" == "--output" ]]; then output="$arg"; fi
  previous="$arg"
done
url="${*: -1}"
case "$url" in
  *DTCZE-14448*) printf '%s' '{"fields":{"status":{"name":"In Progress"}}}' >"$output"; printf '200' ;;
  *DTCZE-14446*) printf '%s' '{"fields":{"status":{"name":"Done"}}}' >"$output"; printf '200' ;;
  *) printf '%s' '{}' >"$output"; printf '404' ;;
esac
EOF
  chmod +x "$target"
}
apply_fake_curl "$fake_bin/curl"

result="$(PATH="$fake_bin:$PATH" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret \
  bash "$SCRIPT" dtcze-14448 DTCZE-14446 DTCZE-14449)"
printf '%s' "$result" | jq -e '
  .issues | length == 3 and
  .[0].ticket_id == "DTCZE-14448" and .[0].status == "In Progress" and
  .[1].ticket_id == "DTCZE-14446" and .[1].status == "Done" and
  .[2].ticket_id == "DTCZE-14449" and .[2].status == null and
  .[2].error == "No encontrado"
' >/dev/null

stdin_result="$(printf '%s\n' dtcze-14446 | PATH="$fake_bin:$PATH" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT")"
printf '%s' "$stdin_result" | jq -e '.issues[0].ticket_id == "DTCZE-14446"' >/dev/null

echo "OK: validación de argumentos, autenticación, argumentos, stdin y estados"
