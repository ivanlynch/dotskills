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
if [ ! -d "$script_dir/skills" ]; then
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

link_skill() {
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

is_dotskills_link() {
  link_path=$(readlink "$1")
  [ "$(basename "$link_path")" = "$2" ] \
    && [ "$(basename "$(dirname "$link_path")")" = skills ] \
    && [ "$(basename "$(dirname "$(dirname "$link_path")")")" = dotskills ]
}

copy_skill() {
  source_path=$1
  target_path=$2
  target_root=$(dirname "$target_path")
  marker="$target_path/.dotskills-managed-copy"
  mkdir -p "$target_root"

  if [ -L "$target_path" ]; then
    if ! is_dotskills_link "$target_path" "$(basename "$source_path")"; then
      echo "No se reemplaza un enlace ajeno: $target_path" >&2
      exit 1
    fi
    stage_path=$(mktemp -d "$target_root/.dotskills-copy.XXXXXX")
    if ! cp -R "$source_path/." "$stage_path/" || ! : > "$stage_path/.dotskills-managed-copy"; then
      rm -rf "$stage_path"
      exit 1
    fi
    rm "$target_path"
    if ! mv "$stage_path" "$target_path"; then
      ln -s "$source_path" "$target_path"
      rm -rf "$stage_path"
      exit 1
    fi
  elif [ -e "$target_path" ]; then
    if [ ! -d "$target_path" ] || [ ! -f "$marker" ]; then
      echo "No se sobrescribe el destino existente: $target_path" >&2
      echo "Haz una copia de seguridad y vuelve a ejecutar el instalador." >&2
      exit 1
    fi
    # shortcut: archivos eliminados de skills/ permanecen en las copias; agregar limpieza por manifiesto si aparecen residuos.
    cp -R "$source_path/." "$target_path/"
  else
    stage_path=$(mktemp -d "$target_root/.dotskills-copy.XXXXXX")
    if ! cp -R "$source_path/." "$stage_path/" || ! : > "$stage_path/.dotskills-managed-copy"; then
      rm -rf "$stage_path"
      exit 1
    fi
    if ! mv "$stage_path" "$target_path"; then
      rm -rf "$stage_path"
      exit 1
    fi
  fi

  echo "Instalado: $target_path"
}

install_agent_skills() {
  target_root=$1
  for skill in "$script_dir"/skills/*; do
    [ -d "$skill" ] || continue
    copy_skill "$skill" "$target_root/$(basename "$skill")"
  done
}

install_claude_skills() {
  target_root=$1
  for skill in "$script_dir"/skills/*; do
    [ -d "$skill" ] || continue
    link_skill "$skill" "$target_root/$(basename "$skill")"
  done
}

install_codex() {
  install_agent_skills "$HOME/.agents/skills"
}

install_claude() {
  install_claude_skills "$HOME/.claude/skills"
}

install_cursor() {
  install_agent_skills "$HOME/.agents/skills"
}

case "$REQUESTED" in
  all) install_codex; install_claude ;;
  codex) install_codex ;;
  claude) install_claude ;;
  cursor) install_cursor ;;
esac

echo "dotskills instalado para: $REQUESTED"
