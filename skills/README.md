# Skills

Cada subcarpeta es un skill canónico único (formato [Agent Skills](https://agentskills.io):
`SKILL.md` + recursos) que `install.sh` symlinkea, sin copiar, a `~/.claude/skills/`
y a `~/.agents/skills/` (leído nativamente por Codex y Cursor). No dupliques
este contenido en `core/`, `claude/skills/`, `claude/commands/`, `codex/skills/`
ni `cursor/commands/` — esas carpetas son solo para los skills que todavía no
se migraron a este formato.
