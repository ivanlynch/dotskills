#!/usr/bin/env bash
set -euo pipefail

# Resolve and pin the Git context for a GitHub pull request.
# Dependencies: bash, git, gh, jq, awk, grep, sort, tr and mktemp.
# The script may fetch missing commit objects from the origin remote. It never
# switches branches, edits working-tree files or writes to GitHub.

INVALID_INPUT=2
DEPENDENCY_MISSING=3
GITHUB_ERROR=4
GIT_ERROR=5
EMPTY_DIFF=6
MAX_FILES=50
MAX_CHANGED_LINES=3000

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
  rm -f "${metadata_file:-}" "${numstat_file:-}" "${commits_file:-}"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || \
    fail "$DEPENDENCY_MISSING" "Falta la dependencia: $command_name"
}

ensure_commit() {
  local sha="$1"
  local fetch_ref="$2"

  if git cat-file -e "${sha}^{commit}" 2>/dev/null; then
    return
  fi

  git remote get-url origin >/dev/null 2>&1 || \
    fail "$GIT_ERROR" "No existe el remoto origin para obtener $sha"

  if ! git fetch --no-tags origin "$fetch_ref" >/dev/null 2>&1; then
    fail "$GIT_ERROR" "No se pudo obtener $fetch_ref desde origin"
  fi

  git cat-file -e "${sha}^{commit}" 2>/dev/null || \
    fail "$GIT_ERROR" "El SHA fijado $sha no está disponible después del fetch"
}

main() {
  if [[ $# -ne 1 || ! "$1" =~ ^[1-9][0-9]*$ ]]; then
    fail "$INVALID_INPUT" "Uso: preparar_revision.sh <numero-pr>"
  fi

  local pr_number="$1"
  local dependency
  for dependency in git gh jq awk grep sort tr mktemp; do
    require_command "$dependency"
  done

  git rev-parse --show-toplevel >/dev/null 2>&1 || \
    fail "$GIT_ERROR" "El directorio actual no pertenece a un repositorio Git"

  metadata_file="$(mktemp)"
  numstat_file="$(mktemp)"
  commits_file="$(mktemp)"
  trap cleanup EXIT

  if ! gh pr view "$pr_number" \
    --json number,url,state,title,baseRefName,baseRefOid,headRefName,headRefOid \
    >"$metadata_file" 2>/dev/null; then
    fail "$GITHUB_ERROR" "No se pudo consultar la PR #$pr_number con gh"
  fi

  if ! jq -e '
    (.number | type == "number") and
    (.url | type == "string" and length > 0) and
    (.state | type == "string" and length > 0) and
    (.title | type == "string") and
    (.baseRefName | type == "string" and length > 0) and
    (.headRefName | type == "string" and length > 0) and
    (.baseRefOid | type == "string" and test("^[0-9a-fA-F]{40}$")) and
    (.headRefOid | type == "string" and test("^[0-9a-fA-F]{40}$"))
  ' "$metadata_file" >/dev/null 2>&1; then
    fail "$GITHUB_ERROR" "GitHub devolvió metadatos incompletos para la PR #$pr_number"
  fi

  local base_ref base_sha head_ref head_sha
  base_ref="$(jq -r '.baseRefName' "$metadata_file")"
  base_sha="$(jq -r '.baseRefOid' "$metadata_file")"
  head_ref="$(jq -r '.headRefName' "$metadata_file")"
  head_sha="$(jq -r '.headRefOid' "$metadata_file")"

  ensure_commit "$base_sha" "$base_ref"
  ensure_commit "$head_sha" "refs/pull/$pr_number/head"

  local merge_base
  if ! merge_base="$(git merge-base "$base_sha" "$head_sha" 2>/dev/null)"; then
    fail "$GIT_ERROR" "No se pudo calcular el merge-base de la PR #$pr_number"
  fi
  [[ "$merge_base" =~ ^[0-9a-fA-F]{40}$ ]] || \
    fail "$GIT_ERROR" "Git devolvió un merge-base inválido: $merge_base"

  set +e
  git diff --quiet "$merge_base" "$head_sha"
  local diff_status=$?
  set -e
  case "$diff_status" in
    0) fail "$EMPTY_DIFF" "La PR #$pr_number no contiene cambios respecto del merge-base" ;;
    1) ;;
    *) fail "$GIT_ERROR" "No se pudo calcular el diff de la PR #$pr_number" ;;
  esac

  if ! git diff --numstat "$merge_base" "$head_sha" >"$numstat_file"; then
    fail "$GIT_ERROR" "No se pudieron calcular las métricas del diff"
  fi

  if ! git log --format='%h%x09%s' "$merge_base..$head_sha" >"$commits_file"; then
    fail "$GIT_ERROR" "No se pudo obtener la lista de commits"
  fi

  local file_count changed_lines oversized
  file_count="$(awk 'END { print NR + 0 }' "$numstat_file")"
  changed_lines="$(awk '
    $1 ~ /^[0-9]+$/ { added += $1 }
    $2 ~ /^[0-9]+$/ { deleted += $2 }
    END { print added + deleted + 0 }
  ' "$numstat_file")"

  oversized=false
  if (( file_count > MAX_FILES || changed_lines > MAX_CHANGED_LINES )); then
    oversized=true
  fi

  local normalized_branch ticket_lines ticket_ids commits
  normalized_branch="$(printf '%s' "$head_ref" | tr '[:lower:]' '[:upper:]')"
  ticket_lines="$(printf '%s\n' "$normalized_branch" | grep -Eo '[A-Z][A-Z0-9]+-[0-9]+' | sort -u || true)"
  ticket_ids="$(printf '%s\n' "$ticket_lines" | jq -R -s 'split("\n") | map(select(length > 0))')"
  commits="$(jq -R -s 'split("\n") | map(select(length > 0))' "$commits_file")"

  jq -n \
    --argjson pr "$(cat "$metadata_file")" \
    --arg merge_base "$merge_base" \
    --argjson ticket_ids "$ticket_ids" \
    --argjson files "$file_count" \
    --argjson changed_lines "$changed_lines" \
    --argjson oversized "$oversized" \
    --argjson max_files "$MAX_FILES" \
    --argjson max_changed_lines "$MAX_CHANGED_LINES" \
    --argjson commits "$commits" \
    '{
      pr: $pr,
      merge_base: $merge_base,
      ticket_ids: $ticket_ids,
      ticket_resolution: (
        if ($ticket_ids | length) == 1 then "resolved"
        elif ($ticket_ids | length) == 0 then "missing"
        else "ambiguous"
        end
      ),
      diff: {
        files: $files,
        changed_lines: $changed_lines,
        oversized: $oversized,
        limits: {files: $max_files, changed_lines: $max_changed_lines}
      },
      commits: $commits
    }'
}

main "$@"
