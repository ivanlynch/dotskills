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

remove_shared_skills() {
  target_root=$1
  for skill in skills/*; do
    [ -d "$skill" ] || continue
    remove_link "$target_root/$(basename "$skill")"
  done
}

remove_codex() {
  remove_shared_skills "$HOME/.agents/skills"
}

remove_claude() {
  remove_shared_skills "$HOME/.claude/skills"
}

remove_cursor() {
  remove_shared_skills "$HOME/.agents/skills"
}

case "$REQUESTED" in
  all) remove_codex; remove_claude; remove_cursor ;;
  codex) remove_codex ;;
  claude) remove_claude ;;
  cursor) remove_cursor ;;
esac
