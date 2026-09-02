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
printf '%s\n' '## Título' '' 'Texto **importante**.' '' '- Elemento 1' '- Elemento 2' > "$tmp_dir/description.md"
printf '%s\n' '#!/usr/bin/env bash' \
  'output=""; data_arg=""; url=""' \
  'while [[ $# -gt 0 ]]; do case "$1" in --output) shift; output="$1" ;; --data-binary) shift; data_arg="$1" ;; http*) url="$1" ;; esac; shift; done' \
  'if [[ "$*" == *"/rest/agile/1.0/sprint/114686/issue"* ]]; then printf "%s" '\''{}'\'' > "$output"; printf "204"; else cp "${data_arg#@}" "$PAYLOAD_CAPTURE"; printf "%s" '\''{"key":"DTCZE-14436","id":"123456"}'\'' > "$output"; printf "201"; fi' > "$tmp_dir/curl"
chmod +x "$tmp_dir/curl"
result="$(PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/payload.json" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md")"
printf '%s' "$result" | jq -e '.issue_key == "DTCZE-14436" and .parent == "DTCZE-12424" and .project == "DTCZE" and .issue_type == "Technical Task" and .url == "https://jira.example/browse/DTCZE-14436"' >/dev/null
jq -e '
  .fields.description.type == "doc" and
  .fields.description.version == 1 and
  ([.fields.description.content[].type] == ["heading", "paragraph", "bulletList"]) and
  .fields.description.content[0].attrs.level == 2 and
  .fields.description.content[1].content[1].marks[0].type == "strong" and
  (.fields.description.content[2].content | length == 2) and
  .fields.customfield_13230 == {id:"61436"} and
  .fields.issuetype == {id:"11737"} and
  .fields.parent == {key:"DTCZE-12424"}
' "$tmp_dir/payload.json" >/dev/null

echo "OK: validación de argumentos, autenticación y creación simulada"
