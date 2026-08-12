#!/usr/bin/env bash
set -euo pipefail

# Transition one Jira issue to Ready for Prod.
# Dependencies: bash, curl and jq. Credentials use JIRA_BASE_URL, JIRA_EMAIL
# and JIRA_API_TOKEN; the token is never printed.

AUTH_REQUIRED=2
NOT_FOUND=3
REQUEST_FAILED=4
DEPENDENCY_MISSING=5
INVALID_INPUT=6
TARGET_STATUS="Ready for Prod"
BOARD_ID="54142"
ISSUE_PATTERN='^[A-Z][A-Z0-9]+-[0-9]+$'

err() { echo "$*" >&2; }
fail() { local code="$1"; shift; err "$*"; exit "$code"; }

cleanup() {
  rm -f "${sprints_file:-}" "${transitions_file:-}" "${response_file:-}" "${output_file:-}"
}

required_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "$AUTH_REQUIRED" "AUTH_REQUIRED: falta $name"
}

request() {
  local output="$1" method="$2" url="$3" http_code
  shift 3
  if ! http_code="$(curl --silent --show-error --location \
    --output "$output" --write-out '%{http_code}' \
    --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header 'User-Agent: codex-jira-skill' \
    --request "$method" "$url" "$@" 2>/dev/null)"; then
    fail "$REQUEST_FAILED" "No se pudo conectar con Jira"
  fi
  case "$http_code" in
    200|204) ;;
    401|403) fail "$AUTH_REQUIRED" "AUTH_REQUIRED: Jira rechazó las credenciales ($http_code)" ;;
    404) fail "$NOT_FOUND" "No se encontró el issue solicitado" ;;
    *) fail "$REQUEST_FAILED" "Jira respondió con HTTP $http_code" ;;
  esac
  printf '%s' "$http_code"
}

main() {
  [[ $# -eq 1 ]] || fail "$INVALID_INPUT" "Uso: transition_ready_for_prod.sh PROJECT-123"
  local ticket_id
  ticket_id="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  [[ "$ticket_id" =~ $ISSUE_PATTERN ]] || fail "$INVALID_INPUT" "El ticket-id debe tener formato PROJECT-123"

  command -v curl >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: curl"
  command -v jq >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: jq"
  required_env JIRA_BASE_URL
  required_env JIRA_EMAIL
  required_env JIRA_API_TOKEN

  local base_url="${JIRA_BASE_URL%/}" matches transition_id transition_name sprint_id sprint_name
  sprints_file="$(mktemp)"
  transitions_file="$(mktemp)"
  response_file="$(mktemp)"
  output_file="$(mktemp)"
  trap cleanup EXIT

  request "$sprints_file" GET "$base_url/rest/agile/1.0/board/$BOARD_ID/sprint?state=active" >/dev/null
  matches="$(jq -c '
    [.values[]? | select((.state | type) == "string" and ((.state | ascii_downcase) == "active"))]
  ' "$sprints_file" 2>/dev/null)" || fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida al consultar sprints"

  [[ "$(jq 'length' <<< "$matches")" -eq 1 ]] || {
    local sprint_count; sprint_count="$(jq 'length' <<< "$matches")"
    [[ "$sprint_count" -eq 0 ]] && fail "$INVALID_INPUT" "No hay un sprint activo en el board $BOARD_ID"
    fail "$INVALID_INPUT" "Hay más de un sprint activo en el board $BOARD_ID"
  }

  sprint_id="$(jq -r '.[0].id // empty' <<< "$matches")"
  sprint_name="$(jq -r '.[0].name // empty' <<< "$matches")"
  [[ -n "$sprint_id" && -n "$sprint_name" ]] || fail "$REQUEST_FAILED" "El sprint activo no tiene un ID o nombre válido"

  printf '%s' '{"issues":["'"$ticket_id"'"]}' > "$output_file"
  request "$response_file" POST "$base_url/rest/agile/1.0/sprint/$sprint_id/issue" --data-binary "@$output_file" >/dev/null

  request "$transitions_file" GET "$base_url/rest/api/3/issue/$ticket_id/transitions" >/dev/null
  matches="$(jq -c --arg target "$TARGET_STATUS" '
    [.transitions[]? | select((.name | type) == "string" and ((.name | ascii_downcase) == ($target | ascii_downcase)))]
  ' "$transitions_file" 2>/dev/null)" || fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida"

  [[ "$(jq 'length' <<< "$matches")" -eq 1 ]] || {
    local count; count="$(jq 'length' <<< "$matches")"
    [[ "$count" -eq 0 ]] && fail "$INVALID_INPUT" "La transición Ready for Prod no está disponible para $ticket_id"
    fail "$INVALID_INPUT" "Hay más de una transición Ready for Prod disponible para $ticket_id"
  }

  transition_id="$(jq -r '.[0].id // empty' <<< "$matches")"
  transition_name="$(jq -r '.[0].name // empty' <<< "$matches")"
  [[ -n "$transition_id" && -n "$transition_name" ]] || fail "$REQUEST_FAILED" "La transición no tiene un ID válido"

  printf '%s' '{"transition":{"id":"'"$transition_id"'"}}' > "$output_file"
  request "$response_file" POST "$base_url/rest/api/3/issue/$ticket_id/transitions" --data-binary "@$output_file" >/dev/null

  jq -n --arg ticket_id "$ticket_id" --arg board_id "$BOARD_ID" --arg sprint_id "$sprint_id" --arg sprint_name "$sprint_name" --arg transition "$transition_name" --arg status "$TARGET_STATUS" \
    '{ticket_id:$ticket_id,board_id:$board_id,sprint_id:$sprint_id,sprint_name:$sprint_name,transition:$transition,status:$status}'
}

main "$@"
