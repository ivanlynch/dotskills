#!/bin/sh
set -eu

REPO_URL="${DOTSKILLS_REPO_URL:-https://github.com/ivanlynch/dotskills.git}"
CACHE_DIR="${DOTSKILLS_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotskills}"
REQUESTED="${1:-all}"

case "$REQUESTED" in
  all|codex|claude|cursor) ;;
  *)
    echo "Uso: install.sh [all|codex|claude|cursor]" >&2
    exit 2
    ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)
if [ ! -d "$script_dir/codex/skills" ]; then
  command -v git >/dev/null 2>&1 || {
    echo "Se necesita git para instalar dotskills." >&2
    exit 1
  }

  if [ -d "$CACHE_DIR/.git" ]; then
    git -C "$CACHE_DIR" pull --ff-only
  else
    mkdir -p "$(dirname "$CACHE_DIR")"
    git clone "$REPO_URL" "$CACHE_DIR"
  fi

  exec sh "$CACHE_DIR/install.sh" "$REQUESTED"
fi

link_file() {
  source_path=$1
  target_path=$2
  mkdir -p "$(dirname "$target_path")"
  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    echo "No se sobrescribe el archivo existente: $target_path" >&2
    echo "Haz una copia de seguridad y vuelve a ejecutar el instalador." >&2
    exit 1
  fi
  rm -f "$target_path"
  ln -s "$source_path" "$target_path"
  echo "Instalado: $target_path"
}

install_shared_skills() {
  target_root=$1
  for skill in "$script_dir"/skills/*; do
    [ -d "$skill" ] || continue
    link_file "$skill" "$target_root/$(basename "$skill")"
  done
}

install_codex() {
  install_shared_skills "$HOME/.agents/skills"
  for skill in "$script_dir"/codex/skills/*; do
    [ -d "$skill" ] || continue
    link_file "$skill" "$HOME/.codex/skills/$(basename "$skill")"
  done
}

install_claude() {
  install_shared_skills "$HOME/.claude/skills"
  for skill in "$script_dir"/claude/skills/*; do
    [ -d "$skill" ] || continue
    link_file "$skill" "$HOME/.claude/skills/$(basename "$skill")"
  done
  for command in "$script_dir"/claude/commands/*.md; do
    [ -f "$command" ] || continue
    [ "$(basename "$command")" = "README.md" ] && continue
    link_file "$command" "$HOME/.claude/commands/$(basename "$command")"
  done
}

install_cursor() {
  install_shared_skills "$HOME/.agents/skills"
  for command in "$script_dir"/cursor/commands/*.md; do
    [ -f "$command" ] || continue
    [ "$(basename "$command")" = "README.md" ] && continue
    link_file "$command" "$HOME/.cursor/commands/$(basename "$command")"
  done
}

case "$REQUESTED" in
  all) install_codex; install_claude; install_cursor ;;
  codex) install_codex ;;
  claude) install_claude ;;
  cursor) install_cursor ;;
esac

echo "dotskills instalado para: $REQUESTED"
