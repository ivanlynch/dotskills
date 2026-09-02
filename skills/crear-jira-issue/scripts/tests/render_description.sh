#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SKILL_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
RENDERER="$SKILL_DIR/scripts/render_description.sh"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

for name in context problem objective scope acceptance out-of-scope resources; do
  printf '%s\n' "$name" > "$TEMP_DIR/$name.txt"
done

"$RENDERER" \
  --context-file "$TEMP_DIR/context.txt" \
  --problem-file "$TEMP_DIR/problem.txt" \
  --objective-file "$TEMP_DIR/objective.txt" \
  --scope-file "$TEMP_DIR/scope.txt" \
  --acceptance-file "$TEMP_DIR/acceptance.txt" \
  --out-of-scope-file "$TEMP_DIR/out-of-scope.txt" \
  --resources-file "$TEMP_DIR/resources.txt" \
  --output-file "$TEMP_DIR/output.md"

expected='## Contexto

context

## Problema

problem

## Objetivo

objective

## Escopo

scope

## Critérios de aceite

acceptance

## Fora de escopo

out-of-scope

## Recursos

resources'
actual="$(cat "$TEMP_DIR/output.md")"
[[ "$actual" == "$expected" ]] || { echo "render output mismatch" >&2; diff -u <(printf '%s\n' "$expected") "$TEMP_DIR/output.md" >&2; exit 1; }

echo "render_description: ok"
