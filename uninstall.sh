#!/bin/sh
set -eu

REQUESTED="${1:-all}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
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

is_dotskills_link() {
  link_path=$(readlink "$1")
  [ "$(basename "$link_path")" = "$2" ] \
    && [ "$(basename "$(dirname "$link_path")")" = skills ] \
    && [ "$(basename "$(dirname "$(dirname "$link_path")")")" = dotskills ]
}

remove_agent_skills() {
  target_root=$1
  for skill in "$script_dir"/skills/*; do
    [ -d "$skill" ] || continue
    target_path="$target_root/$(basename "$skill")"
    if [ -L "$target_path" ]; then
      if is_dotskills_link "$target_path" "$(basename "$skill")"; then
        rm "$target_path"
        echo "Eliminado: $target_path"
      fi
    elif [ -d "$target_path" ] && [ -f "$target_path/.dotskills-managed-copy" ]; then
      rm -r "$target_path"
      echo "Eliminado: $target_path"
    fi
  done
}

remove_claude_skills() {
  target_root=$1
  for skill in "$script_dir"/skills/*; do
    [ -d "$skill" ] || continue
    remove_link "$target_root/$(basename "$skill")"
  done
}

remove_codex() {
  remove_agent_skills "$HOME/.agents/skills"
}

remove_claude() {
  remove_claude_skills "$HOME/.claude/skills"
}

remove_cursor() {
  remove_agent_skills "$HOME/.agents/skills"
}

case "$REQUESTED" in
  all) remove_codex; remove_claude ;;
  codex) remove_codex ;;
  claude) remove_claude ;;
  cursor) remove_cursor ;;
esac
