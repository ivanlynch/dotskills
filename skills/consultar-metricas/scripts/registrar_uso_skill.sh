#!/usr/bin/env bash
set -euo pipefail

# Hook de Claude Code (evento PreToolUse, matcher "Skill"): registra cada
# invocación de un skill en un log de uso. No se invoca como parte del flujo
# normal de este skill — hay que agregarlo a mano a ~/.claude/settings.json
# (ver SKILL.md, sección "Configurar el hook").
#
# Dependencias: bash, grep, sed, date. Ninguna externa.
#
# Recibe por stdin el JSON que manda Claude Code para el evento PreToolUse,
# con esta forma (verificado empíricamente contra un hook real; no está
# documentado con este nivel de detalle en code.claude.com/docs):
#   {"tool_name":"Skill","tool_input":{"skill":"<nombre>","args":"..."}, ...}
#
# Este hook NUNCA debe bloquear la invocación real del skill: no usa 'exit'
# con códigos distintos de 0, ni deja que un stdin vacío o malformado lo
# tire abajo.

DOTSKILLS_HOME="${DOTSKILLS_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotskills}"
LOG="$DOTSKILLS_HOME/metricas/uso_skills.log"

registrar() {
  local payload skill
  payload="$(cat)"

  skill="$(printf '%s' "$payload" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
  [ -n "$skill" ] || skill="desconocido"

  mkdir -p "$(dirname "$LOG")"
  printf '%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$skill" >> "$LOG"
}

registrar 2>/dev/null || true
exit 0
