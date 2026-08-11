#!/usr/bin/env bash
set -euo pipefail

# Return the subtasks of a Jira issue as JSON.
# Dependencies: bash, curl and jq. Credentials use JIRA_BASE_URL, JIRA_EMAIL
# and JIRA_API_TOKEN; the token is never printed.

AUTH_REQUIRED=2
NOT_FOUND=3
REQUEST_FAILED=4
DEPENDENCY_MISSING=5
ISSUE_PATTERN='^[A-Z][A-Z0-9]+-[0-9]+$'

err() {
  echo "$*" >&2
}

fail() {
  local code="$1"
  shift
  err "$*"
  exit "$code"
}

cleanup() {
  rm -f "${response_file:-}" "${output_file:-}"
}

required_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    fail "$AUTH_REQUIRED" "AUTH_REQUIRED: falta $name"
  fi
}

main() {
  if [[ $# -ne 1 ]]; then
    fail "$REQUEST_FAILED" "Uso: get_subtasks.sh PROJECT-123"
  fi

  local ticket_id
  ticket_id="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  [[ "$ticket_id" =~ $ISSUE_PATTERN ]] || \
    fail "$REQUEST_FAILED" "El ticket-id debe tener formato PROJECT-123"

  command -v curl >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: curl"
  command -v jq >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: jq"

  required_env JIRA_BASE_URL
  required_env JIRA_EMAIL
  required_env JIRA_API_TOKEN

  local base_url="${JIRA_BASE_URL%/}"
  local http_code
  response_file="$(mktemp)"
  output_file="$(mktemp)"
  trap cleanup EXIT

  if ! http_code="$(curl --silent --show-error --location \
    --output "$response_file" --write-out '%{http_code}' \
    --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Accept: application/json' \
    --header 'User-Agent: codex-jira-skill' \
    "$base_url/rest/api/3/issue/$ticket_id?fields=subtasks" 2>/dev/null)"; then
    fail "$REQUEST_FAILED" "No se pudo conectar con Jira"
  fi

  case "$http_code" in
    200) ;;
    401|403) fail "$AUTH_REQUIRED" "AUTH_REQUIRED: Jira rechazó las credenciales ($http_code)" ;;
    404) fail "$NOT_FOUND" "No se encontró el issue $ticket_id" ;;
    *) fail "$REQUEST_FAILED" "Jira respondió con HTTP $http_code" ;;
  esac

  if ! jq -e --arg ticket_id "$ticket_id" '
    (.fields.subtasks // []) as $subtasks |
    if ($subtasks | type) != "array" or
       ([$subtasks[] | select((.key | type) != "string" or
                              (.fields.summary | type) != "string")] | length) > 0
    then error("respuesta inválida")
    else {
      ticket_id: $ticket_id,
      subtasks: [$subtasks[] | {ticket_id: .key, title: .fields.summary}]
    }
    end
  ' "$response_file" >"$output_file" 2>/dev/null; then
    fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida"
  fi
  cat "$output_file"
}

main "$@"
