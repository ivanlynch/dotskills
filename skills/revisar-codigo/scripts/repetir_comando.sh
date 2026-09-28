#!/usr/bin/env bash
set -euo pipefail

# Run the same command twice in one directory and preserve both outputs.
# Dependencies: bash, jq, mktemp, cmp, cksum and a command supplied by the user.
# The script exits successfully when both executions complete, even if the
# reviewed command fails; command exit codes are recorded in the JSON result.

INVALID_INPUT=2
DEPENDENCY_MISSING=3

err() {
  echo "$*" >&2
}

fail() {
  local code="$1"
  shift
  err "$*"
  exit "$code"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || \
    fail "$DEPENDENCY_MISSING" "Falta la dependencia: $command_name"
}

main() {
  if [[ $# -lt 3 || "$2" != "--" ]]; then
    fail "$INVALID_INPUT" "Uso: repetir_comando.sh <directorio> -- <comando> [argumentos...]"
  fi

  local workdir="$1"
  shift 2
  [[ -d "$workdir" ]] || \
    fail "$INVALID_INPUT" "No existe el directorio de ejecución: $workdir"

  local dependency
  for dependency in jq mktemp cmp cksum; do
    require_command "$dependency"
  done
  if [[ "$1" == */* ]]; then
    local command_path="$1"
    [[ "$command_path" == /* ]] || command_path="$workdir/$command_path"
    [[ -x "$command_path" ]] || \
      fail "$DEPENDENCY_MISSING" "No existe o no es ejecutable: $1"
  else
    command -v "$1" >/dev/null 2>&1 || \
      fail "$DEPENDENCY_MISSING" "No existe el comando a ejecutar: $1"
  fi

  local result_dir run_one_log run_two_log
  result_dir="$(mktemp -d "${TMPDIR:-/tmp}/revisar-codigo-repeticion.XXXXXX")"
  run_one_log="$result_dir/ejecucion-1.log"
  run_two_log="$result_dir/ejecucion-2.log"

  set +e
  (cd "$workdir" && "$@") >"$run_one_log" 2>&1
  local run_one_status=$?
  (cd "$workdir" && "$@") >"$run_two_log" 2>&1
  local run_two_status=$?
  set -e

  local same_status=false
  local same_output=false
  [[ "$run_one_status" -eq "$run_two_status" ]] && same_status=true
  cmp -s "$run_one_log" "$run_two_log" && same_output=true

  local run_one_checksum run_two_checksum command_display argument escaped
  run_one_checksum="$(cksum <"$run_one_log" | awk '{ print $1 ":" $2 }')"
  run_two_checksum="$(cksum <"$run_two_log" | awk '{ print $1 ":" $2 }')"
  command_display=""
  for argument in "$@"; do
    printf -v escaped '%q' "$argument"
    command_display="${command_display}${escaped} "
  done
  command_display="${command_display% }"

  jq -n \
    --arg directory "$workdir" \
    --arg command "$command_display" \
    --arg result_directory "$result_dir" \
    --arg run_one_log "$run_one_log" \
    --arg run_two_log "$run_two_log" \
    --arg run_one_checksum "$run_one_checksum" \
    --arg run_two_checksum "$run_two_checksum" \
    --argjson run_one_status "$run_one_status" \
    --argjson run_two_status "$run_two_status" \
    --argjson same_status "$same_status" \
    --argjson same_output "$same_output" \
    '{
      directory: $directory,
      command: $command,
      result_directory: $result_directory,
      executions: [
        {number: 1, exit_code: $run_one_status, log: $run_one_log, checksum: $run_one_checksum},
        {number: 2, exit_code: $run_two_status, log: $run_two_log, checksum: $run_two_checksum}
      ],
      same_exit_code: $same_status,
      same_output: $same_output,
      byte_identical: ($same_status and $same_output)
    }'
}

main "$@"
