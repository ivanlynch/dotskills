#!/usr/bin/env bash
set -euo pipefail

# Create a Jira Sub-task under DTCZE-12424.
# Dependencies: bash, curl and jq. Credentials use JIRA_BASE_URL, JIRA_EMAIL
# and JIRA_API_TOKEN; the token is never printed.

AUTH_REQUIRED=2
NOT_FOUND=3
REQUEST_FAILED=4
DEPENDENCY_MISSING=5
INVALID_INPUT=6
PROJECT_KEY="DTCZE"
PARENT_KEY="DTCZE-12424"
ISSUE_TYPE="Sub-task"

err() { echo "$*" >&2; }
fail() { local code="$1"; shift; err "$*"; exit "$code"; }

cleanup() {
  rm -f "${payload_file:-}" "${response_file:-}" "${output_file:-}"
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
  output_file="$(mktemp)"
  trap cleanup EXIT

  jq -n \
    --arg project "$PROJECT_KEY" \
    --arg parent "$PARENT_KEY" \
    --arg issue_type "$ISSUE_TYPE" \
    --arg summary "$title" \
    --arg description "$description" \
    '{fields:{project:{key:$project},parent:{key:$parent},issuetype:{name:$issue_type},summary:$summary,description:{type:"doc",version:1,content:[{type:"paragraph",content:[{type:"text",text:$description}]}]}}}' \
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
    404) fail "$NOT_FOUND" "No se encontró el proyecto o parent $PARENT_KEY" ;;
    400) fail "$INVALID_INPUT" "Jira rechazó el payload o el tipo de issue" ;;
    *) fail "$REQUEST_FAILED" "Jira respondió con HTTP $http_code" ;;
  esac

  jq -e --arg parent "$PARENT_KEY" --arg project "$PROJECT_KEY" --arg issue_type "$ISSUE_TYPE" --arg title "$title" '
    if ((.key | type) == "string" and (.id | type) == "string") then
      {issue_key:.key,issue_id:.id,parent:$parent,project:$project,issue_type:$issue_type,title:$title}
    else error("respuesta inválida") end
  ' "$response_file" > "$output_file" 2>/dev/null || fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida"

  local issue_key
  issue_key="$(jq -r '.issue_key' "$output_file")"
  jq --arg url "$base_url/browse/$issue_key" '. + {url:$url}' "$output_file"
}

main "$@"
