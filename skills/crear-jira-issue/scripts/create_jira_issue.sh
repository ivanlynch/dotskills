#!/usr/bin/env bash
set -euo pipefail

# Create a Jira Technical Task under DTCZE-12424.
# Dependencies: bash, curl and jq. Credentials use JIRA_BASE_URL, JIRA_EMAIL
# and JIRA_API_TOKEN; the token is never printed.

AUTH_REQUIRED=2
NOT_FOUND=3
REQUEST_FAILED=4
DEPENDENCY_MISSING=5
INVALID_INPUT=6
PROJECT_KEY="DTCZE"
ISSUE_TYPE="Technical Task"
ISSUE_TYPE_ID="11737"
PARENT_KEY="DTCZE-12424"
SPRINT_FIELD="customfield_10007"
SPRINT_ID="114686"
TEAM_FIELD="customfield_13230"
TEAM_OPTION_ID="61436"

err() { echo "$*" >&2; }
fail() { local code="$1"; shift; err "$*"; exit "$code"; }

cleanup() {
  rm -f "${payload_file:-}" "${response_file:-}" "${sprint_response_file:-}" "${output_file:-}"
}

required_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "$AUTH_REQUIRED" "AUTH_REQUIRED: falta $name"
}

main() {
  local title_file="" description_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title-file) [[ $# -ge 2 ]] || fail "$INVALID_INPUT" "Falta el valor de --title-file"; title_file="$2"; shift 2 ;;
      --description-file) [[ $# -ge 2 ]] || fail "$INVALID_INPUT" "Falta el valor de --description-file"; description_file="$2"; shift 2 ;;
      *) fail "$INVALID_INPUT" "Argumento desconocido: $1" ;;
    esac
  done
  [[ -f "$title_file" ]] || fail "$INVALID_INPUT" "No existe el archivo de título"
  [[ -f "$description_file" ]] || fail "$INVALID_INPUT" "No existe el archivo de descripción"

  local title description
  title="$(sed 's/[[:space:]]*$//' "$title_file")"
  description="$(sed 's/[[:space:]]*$//' "$description_file")"
  [[ -n "$title" ]] || fail "$INVALID_INPUT" "El título está vacío"
  [[ -n "$description" ]] || fail "$INVALID_INPUT" "La descripción está vacía"

  command -v curl >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: curl"
  command -v jq >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: jq"
  required_env JIRA_BASE_URL
  required_env JIRA_EMAIL
  required_env JIRA_API_TOKEN

  local base_url="${JIRA_BASE_URL%/}" http_code
  payload_file="$(mktemp)"
  response_file="$(mktemp)"
  sprint_response_file="$(mktemp)"
  output_file="$(mktemp)"
  trap cleanup EXIT

  # Jira Cloud expects Atlassian Document Format (ADF), not Markdown text.
  # Convert the Markdown produced by the interview into block nodes and the
  # most common inline marks before sending the request.
  jq -n \
    --arg project "$PROJECT_KEY" \
    --arg parent "$PARENT_KEY" \
    --arg issue_type "$ISSUE_TYPE" \
    --arg issue_type_id "$ISSUE_TYPE_ID" \
    --arg team_field "$TEAM_FIELD" \
    --arg team_option_id "$TEAM_OPTION_ID" \
    --arg summary "$title" \
    --rawfile description "$description_file" '
      def inline_nodes:
        if length == 0 then []
        elif test("^\\*\\*[^*]+\\*\\*") then
          (capture("^\\*\\*(?<value>[^*]+)\\*\\*") as $match |
            [{type:"text",text:$match.value,marks:[{type:"strong"}]}] +
            (.[(($match.value|length) + 4):] | inline_nodes))
        elif test("^`[^`]+`") then
          (capture("^`(?<value>[^`]+)`") as $match |
            [{type:"text",text:$match.value,marks:[{type:"code"}]}] +
            (.[(($match.value|length) + 2):] | inline_nodes))
        elif test("^\\[[^]]+\\]\\([^)]*\\)") then
          (capture("^\\[(?<text>[^]]+)\\]\\((?<url>[^)]*)\\)") as $match |
            [{type:"text",text:$match.text,marks:[{type:"link",attrs:{href:$match.url}}]}] +
            (.[(($match.text|length) + ($match.url|length) + 4):] | inline_nodes))
        elif test("^[^*`\\[]+") then
          (match("^[^*`\\[]+") as $match |
            [{type:"text",text:$match.string}] + (.[($match.length):] | inline_nodes))
        else
          [{type:"text",text:.[0:1]}] + (.[1:] | inline_nodes)
        end;

      def flush_paragraph:
        if (.paragraph|length) > 0 then
          .blocks += [{type:"paragraph",content:(.paragraph|join("\n")|inline_nodes)}] |
          .paragraph=[]
        else . end;

      def flush_bullets:
        if (.bullets|length) > 0 then
          .blocks += [{type:"bulletList",content:(.bullets|map({
            type:"listItem",
            content:[{type:"paragraph",content:(.text|inline_nodes)}]
          }))}] |
          .bullets=[]
        else . end;

      def flush_all: flush_paragraph | flush_bullets;

      ($description|split("\n")|reduce .[] as $line
        ({blocks:[],paragraph:[],bullets:[]};
          if ($line|test("^#{1,6} ")) then
            flush_all |
            ($line|capture("^(?<hashes>#+) (?<text>.*)$")) as $heading |
            .blocks += [{type:"heading",attrs:{level:($heading.hashes|length)},content:($heading.text|inline_nodes)}]
          elif ($line|test("^- ")) then
            flush_paragraph |
            .bullets += [{text:($line|sub("^- ";""))}]
          elif ($line|length) == 0 then
            flush_all
          else
            flush_bullets |
            .paragraph += [$line]
          end
        )
      | flush_all
      | {fields:{
          project:{key:$project},
          parent:{key:$parent},
          issuetype:{id:$issue_type_id},
          summary:$summary,
          ($team_field):{id:$team_option_id},
          description:{type:"doc",version:1,content:.blocks}
        }}
      )
    ' \
    > "$payload_file" || fail "$REQUEST_FAILED" "No se pudo construir el payload de Jira"

  if ! http_code="$(curl --silent --show-error --location \
    --output "$response_file" --write-out '%{http_code}' \
    --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'User-Agent: codex-jira-skill' \
    --data-binary "@$payload_file" \
    --request POST "$base_url/rest/api/3/issue" 2>/dev/null)"; then
    fail "$REQUEST_FAILED" "No se pudo conectar con Jira"
  fi

  case "$http_code" in
    201) ;;
    401|403) fail "$AUTH_REQUIRED" "AUTH_REQUIRED: Jira rechazó las credenciales ($http_code)" ;;
    404) fail "$NOT_FOUND" "No se encontró el proyecto DTCZE o el tipo Technical Task" ;;
    400)
      local jira_message
      jira_message="$(jq -r '([.errorMessages[]?, (.errors // {} | to_entries[] | "\(.key): \(.value)")] | join("; ")) // empty' "$response_file" 2>/dev/null || true)"
      [[ -n "$jira_message" ]] || jira_message="payload o tipo de issue inválido"
      fail "$INVALID_INPUT" "Jira rechazó el payload: $jira_message"
      ;;
    *) fail "$REQUEST_FAILED" "Jira respondió con HTTP $http_code" ;;
  esac

  jq -e --arg parent "$PARENT_KEY" --arg project "$PROJECT_KEY" --arg issue_type "$ISSUE_TYPE" --arg title "$title" '
    if ((.key | type) == "string" and (.id | type) == "string") then
      {issue_key:.key,issue_id:.id,parent:$parent,project:$project,issue_type:$issue_type,title:$title}
    else error("respuesta inválida") end
  ' "$response_file" > "$output_file" 2>/dev/null || fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida"

  local issue_key
  issue_key="$(jq -r '.issue_key' "$output_file")"

  local sprint_http_code
  if ! sprint_http_code="$(curl --silent --show-error --location \
    --output "$sprint_response_file" --write-out '%{http_code}' \
    --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'User-Agent: codex-jira-skill' \
    --data-binary "$(jq -nc --arg issue_key "$issue_key" '{issues:[$issue_key]}')" \
    --request POST "$base_url/rest/agile/1.0/sprint/$SPRINT_ID/issue" 2>/dev/null)"; then
    fail "$REQUEST_FAILED" "Issue $issue_key fue creado, pero no se pudo asociar al sprint $SPRINT_ID"
  fi

  case "$sprint_http_code" in
    200|201|204) ;;
    401|403) fail "$AUTH_REQUIRED" "Issue $issue_key fue creado, pero Jira rechazó la asociación al sprint ($sprint_http_code)" ;;
    *) fail "$REQUEST_FAILED" "Issue $issue_key fue creado, pero Jira respondió HTTP $sprint_http_code al asociar el sprint" ;;
  esac

  jq --arg url "$base_url/browse/$issue_key" '. + {url:$url}' "$output_file"
}

main "$@"
