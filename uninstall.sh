#!/bin/sh
set -eu

REQUESTED="${1:-all}"
case "$REQUESTED" in
  all|codex|claude|cursor) ;;
  *) echo "Uso: uninstall.sh [all|codex|claude|cursor]" >&2; exit 2 ;;
esac

remove_link() {
  target_path=$1
  if [ -L "$target_path" ]; then
    rm "$target_path"
    echo "Eliminado: $target_path"
  fi
}

remove_codex() {
  for skill in codex/skills/*; do
    [ -d "$skill" ] || continue
    remove_link "$HOME/.codex/skills/$(basename "$skill")"
  done
}

remove_claude() {
  for skill in claude/skills/*; do
    [ -d "$skill" ] || continue
    remove_link "$HOME/.claude/skills/$(basename "$skill")"
  done
  for command in claude/commands/*.md; do
    [ -f "$command" ] || continue
    [ "$(basename "$command")" = "README.md" ] && continue
    remove_link "$HOME/.claude/commands/$(basename "$command")"
  done
}

remove_cursor() {
  for command in cursor/commands/*.md; do
    [ -f "$command" ] || continue
    [ "$(basename "$command")" = "README.md" ] && continue
    remove_link "$HOME/.cursor/commands/$(basename "$command")"
  done
}

case "$REQUESTED" in
  all) remove_codex; remove_claude; remove_cursor ;;
  codex) remove_codex ;;
  claude) remove_claude ;;
  cursor) remove_cursor ;;
esac
