# dotskills

Reusable AI workflows for Codex, Claude Code, and Cursor.

## Install

Install every adapter globally with one command:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- all
```

Install only one tool:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- codex
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- claude
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- cursor
```

The installer keeps a clone in `~/.local/share/dotskills` and creates symbolic
links in each tool's global directory. Re-running the installer updates the
clone and refreshes the links. To remove the links, run `./uninstall.sh` from
the cached clone.

## Structure

- `core/`: tool-independent workflow definitions.
- `scripts/`: shared helper scripts.
- `codex/skills/`: Codex skills and OpenAI-specific metadata.
- `claude/skills/`: Claude Code skill adapters.
- `claude/commands/`: Claude Code slash-command adapters.
- `cursor/commands/`: Cursor command adapters.
- `cursor/rules/`: Cursor rule adapters.

The Codex skills are under `codex/skills/`. Claude Code and Cursor adapters are
generated from those workflows and use their native slash-command formats.
