# dotskills

Reusable AI workflows for Codex, Claude Code, and Cursor.

## Structure

- `core/`: tool-independent workflow definitions.
- `scripts/`: shared helper scripts.
- `codex/skills/`: Codex skills and OpenAI-specific metadata.
- `claude/skills/`: Claude Code skill adapters.
- `claude/commands/`: Claude Code slash-command adapters.
- `cursor/commands/`: Cursor command adapters.
- `cursor/rules/`: Cursor rule adapters.

The current implementation is under `codex/skills/`. The other directories are
reserved for the portable definitions and adapters.
