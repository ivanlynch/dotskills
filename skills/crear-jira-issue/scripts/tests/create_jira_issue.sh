#!/usr/bin/env bash
set -euo pipefail

# Dependencies: bash and jq. Jira calls use a fake curl executable; no network is used.
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
assert_status 6 bash "$SCRIPT" --parent-key "" --title-file "$SCRIPT" --description-file "$SCRIPT"
assert_status 2 env -u JIRA_BASE_URL -u JIRA_EMAIL -u JIRA_API_TOKEN bash "$SCRIPT" --title-file "$SCRIPT" --description-file "$SCRIPT"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
printf '%s\n' 'Título de prueba' > "$tmp_dir/title.txt"
printf '%s\n' '## Título' '' 'Texto **importante**.' '' '- Elemento 1' '- Elemento 2' > "$tmp_dir/description.md"
cat > "$tmp_dir/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
output=""; method="GET"; data_arg=""; url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) output="$2"; shift 2 ;;
    --request) method="$2"; shift 2 ;;
    --data-binary) data_arg="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
printf '%s %s\n' "$method" "$url" >> "$CURL_TRACE"
if [[ "$method" == GET && "$url" == *"/rest/api/3/issue/${TEST_PARENT_KEY:-DTCZE-14437}?fields=project,issuetype,customfield_13230" ]]; then
  parent_project="${PARENT_PROJECT:-DTCZE}"
  is_subtask="${PARENT_IS_SUBTASK:-false}"
  if [[ "$parent_project" == DTCZE ]]; then
    printf '{"fields":{"project":{"key":"%s"},"issuetype":{"subtask":%s},"customfield_13230":{"id":"61436"}}}' "$parent_project" "$is_subtask" > "$output"
  else
    printf '{"fields":{"project":{"key":"%s"},"issuetype":{"subtask":%s}}}' "$parent_project" "$is_subtask" > "$output"
  fi
  printf '200'
elif [[ "$method" == GET && "$url" == *"/rest/api/3/issue/createmeta/${PARENT_PROJECT:-DTCZE}/issuetypes?maxResults=100" ]]; then
  if [[ "${NO_SUBTASK_TYPES:-0}" == 1 ]]; then
    printf '%s' '{"issueTypes":[{"id":"11737","name":"Technical Task","subtask":false}],"maxResults":1,"startAt":0,"total":1}' > "$output"
  elif [[ "${PAGINATED_SUBTASK_TYPES:-0}" == 1 ]]; then
    printf '%s' '{"issueTypes":[{"id":"10001","name":"Technical Sub-task","subtask":true}],"maxResults":1,"startAt":0,"total":101}' > "$output"
  elif [[ "${MULTIPLE_SUBTASK_TYPES:-0}" == 1 ]]; then
    printf '%s' '{"issueTypes":[{"id":"10001","name":"Technical Sub-task","subtask":true},{"id":"10002","name":"QA Sub-task","subtask":true},{"id":"11737","name":"Technical Task","subtask":false}],"maxResults":3,"startAt":0,"total":3}' > "$output"
  else
    printf '%s' '{"issueTypes":[{"id":"10001","name":"Technical Sub-task","subtask":true},{"id":"11737","name":"Technical Task","subtask":false}],"maxResults":2,"startAt":0,"total":2}' > "$output"
  fi
  printf '200'
elif [[ "$method" == POST && "$url" == *"/rest/api/3/issue" ]]; then
  cp "${data_arg#@}" "$PAYLOAD_CAPTURE"
  printf '{"key":"%s-14436","id":"123456"}' "${PARENT_PROJECT:-DTCZE}" > "$output"; printf '201'
else
  printf '%s' '{}' > "$output"; printf '500'
fi
CURL
chmod +x "$tmp_dir/curl"

result="$(PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/default-payload.json" CURL_TRACE="$tmp_dir/default-trace.txt" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md")"
printf '%s' "$result" | jq -e '.issue_key == "DTCZE-14436" and .parent == "DTCZE-12424" and .project == "DTCZE" and .issue_type == "Technical Task" and .url == "https://jira.example/browse/DTCZE-14436"' >/dev/null
jq -e '
  .fields.description.type == "doc" and
  .fields.description.version == 1 and
  ([.fields.description.content[].type] == ["heading", "paragraph", "bulletList"]) and
  .fields.description.content[0].attrs.level == 2 and
  .fields.description.content[1].content[1].marks[0].type == "strong" and
  (.fields.description.content[2].content | length == 2) and
  .fields.customfield_13230 == {id:"61436"} and
  .fields.customfield_10007 == null and
  .fields.issuetype == {id:"11737"} and
  .fields.parent == {key:"DTCZE-12424"}
' "$tmp_dir/default-payload.json" >/dev/null
! grep -q '/rest/agile/1.0/sprint/' "$tmp_dir/default-trace.txt"

result="$(PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/subtask-payload.json" CURL_TRACE="$tmp_dir/subtask-trace.txt" JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437)"
printf '%s' "$result" | jq -e '.issue_key == "DTCZE-14436" and .parent == "DTCZE-14437" and .project == "DTCZE" and .issue_type == "Technical Sub-task" and .url == "https://jira.example/browse/DTCZE-14436"' >/dev/null
jq -e '
  .fields.project == {key:"DTCZE"} and
  .fields.parent == {key:"DTCZE-14437"} and
  .fields.issuetype == {id:"10001"} and
  .fields.customfield_13230 == {id:"61436"} and
  .fields.summary == "Título de prueba" and
  .fields.description.type == "doc"
' "$tmp_dir/subtask-payload.json" >/dev/null
! grep -q '/rest/agile/1.0/sprint/' "$tmp_dir/subtask-trace.txt"

result="$(PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/cross-project-payload.json" CURL_TRACE="$tmp_dir/cross-project-trace.txt" TEST_PARENT_KEY=OPS-14437 PARENT_PROJECT=OPS JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key OPS-14437)"
printf '%s' "$result" | jq -e '.issue_key == "OPS-14436" and .parent == "OPS-14437" and .project == "OPS" and .issue_type == "Technical Sub-task"' >/dev/null
jq -e '.fields.project == {key:"OPS"} and .fields.parent == {key:"OPS-14437"} and .fields.customfield_13230 == null' "$tmp_dir/cross-project-payload.json" >/dev/null

set +e
PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/selected-subtask-payload.json" CURL_TRACE="$tmp_dir/selected-subtask-trace.txt" MULTIPLE_SUBTASK_TYPES=1 JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437 >/dev/null 2>"$tmp_dir/multiple-types-error.txt"
actual=$?
set -e
[[ "$actual" -eq 6 ]] || { echo "Se esperaba exit code 6 para varios tipos de subtarea, se obtuvo $actual" >&2; exit 1; }
grep -q '10001: Technical Sub-task, 10002: QA Sub-task' "$tmp_dir/multiple-types-error.txt"

PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/selected-subtask-payload.json" CURL_TRACE="$tmp_dir/selected-subtask-trace.txt" MULTIPLE_SUBTASK_TYPES=1 JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437 --subtask-issue-type-id 10002 >/dev/null
jq -e '.fields.issuetype == {id:"10002"}' "$tmp_dir/selected-subtask-payload.json" >/dev/null

assert_status 6 env PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/parent-subtask-payload.json" CURL_TRACE="$tmp_dir/parent-subtask-trace.txt" PARENT_IS_SUBTASK=true JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437
! grep -q 'POST https://jira.example/rest/api/3/issue' "$tmp_dir/parent-subtask-trace.txt"

assert_status 3 env PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/no-type-payload.json" CURL_TRACE="$tmp_dir/no-type-trace.txt" NO_SUBTASK_TYPES=1 JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437
! grep -q 'POST https://jira.example/rest/api/3/issue' "$tmp_dir/no-type-trace.txt"

assert_status 4 env PATH="$tmp_dir:$PATH" PAYLOAD_CAPTURE="$tmp_dir/paginated-payload.json" CURL_TRACE="$tmp_dir/paginated-trace.txt" PAGINATED_SUBTASK_TYPES=1 JIRA_BASE_URL=https://jira.example JIRA_EMAIL=user@example JIRA_API_TOKEN=secret bash "$SCRIPT" --title-file "$tmp_dir/title.txt" --description-file "$tmp_dir/description.md" --parent-key DTCZE-14437
! grep -q 'POST https://jira.example/rest/api/3/issue' "$tmp_dir/paginated-trace.txt"

echo "OK: argumentos, autenticación, creación independiente y subtarea simulada"
