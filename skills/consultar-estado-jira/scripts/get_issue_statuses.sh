#!/usr/bin/env bash
set -euo pipefail

# Return the current status of multiple Jira issues as JSON.
# Dependencies: bash, curl and jq. Credentials use JIRA_BASE_URL, JIRA_EMAIL
# and JIRA_API_TOKEN; the token is never printed.

INVALID_INPUT=1
AUTH_REQUIRED=2
REQUEST_FAILED=3
DEPENDENCY_MISSING=5
ISSUE_PATTERN='^[A-Z][A-Z0-9]+-[0-9]+$'

err() { echo "$*" >&2; }

fail() {
  local code="$1"
  shift
  err "$*"
  exit "$code"
}

required_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "$AUTH_REQUIRED" "AUTH_REQUIRED: falta $name"
}

cleanup() {
  rm -f "${response_file:-}" "${result_file:-}"
}

main() {
  local -a raw_ids=()
  if [[ "$#" -gt 0 ]]; then
    raw_ids=("$@")
  else
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line//$'\r'/}"
      [[ -n "${line//[[:space:]]/}" ]] && raw_ids+=("$line")
    done
  fi

  [[ "${#raw_ids[@]}" -gt 0 ]] || fail "$INVALID_INPUT" "Debe proporcionar al menos un ticket Jira"
  command -v curl >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: curl"
  command -v jq >/dev/null 2>&1 || fail "$DEPENDENCY_MISSING" "Falta la dependencia: jq"
  required_env JIRA_BASE_URL
  required_env JIRA_EMAIL
  required_env JIRA_API_TOKEN

  local base_url="${JIRA_BASE_URL%/}" ticket_id http_code raw_id
  local response_file result_file
  response_file="$(mktemp)"
  result_file="$(mktemp)"
  trap cleanup EXIT

  : >"$result_file"
  for raw_id in "${raw_ids[@]}"; do
    ticket_id="$(printf '%s' "$raw_id" | tr '[:lower:]' '[:upper:]')"
    [[ "$ticket_id" =~ $ISSUE_PATTERN ]] || \
      fail "$INVALID_INPUT" "El ticket-id debe tener formato PROJECT-123: $raw_id"

    if ! http_code="$(curl --silent --show-error --location \
      --output "$response_file" --write-out '%{http_code}' \
      --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
      --header 'Accept: application/json' \
      --header 'User-Agent: codex-jira-skill' \
      "$base_url/rest/api/3/issue/$ticket_id?fields=status" 2>/dev/null)"; then
      fail "$REQUEST_FAILED" "No se pudo conectar con Jira al consultar $ticket_id"
    fi

    case "$http_code" in
      200)
        jq -e --arg ticket_id "$ticket_id" --arg url "$base_url/browse/$ticket_id" '
          (.fields.status.name // empty) as $status |
          if ($status | type) != "string" or ($status | length) == 0
          then error("respuesta inválida")
          else {ticket_id: $ticket_id, status: $status, url: $url}
          end
        ' "$response_file" >>"$result_file" 2>/dev/null ||
          fail "$REQUEST_FAILED" "Jira devolvió una respuesta inválida para $ticket_id"
        ;;
      401|403)
        fail "$AUTH_REQUIRED" "AUTH_REQUIRED: Jira rechazó las credenciales ($http_code)"
        ;;
      404)
        jq -cn --arg ticket_id "$ticket_id" --arg url "$base_url/browse/$ticket_id" \
          '{ticket_id: $ticket_id, status: null, error: "No encontrado", url: $url}' >>"$result_file"
        ;;
      *)
        fail "$REQUEST_FAILED" "Jira respondió con HTTP $http_code al consultar $ticket_id"
        ;;
    esac
  done

  jq -s '{issues: .}' "$result_file"
}

main "$@"
