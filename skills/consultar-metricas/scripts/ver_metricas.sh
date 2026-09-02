#!/usr/bin/env bash
set -euo pipefail

# Agrega $DOTSKILLS_HOME/metricas/uso_skills.log (una línea por invocación,
# escrita por registrar_uso_skill.sh) y muestra cuántas veces se usó cada
# skill, de más a menos.
#
# Dependencias: bash, cut, sort, uniq. Ninguna externa.
#
# Sin registros todavía (log ausente o vacío): imprime exactamente
# "No hay registros de uso de skills todavía." — SKILL.md usa ese texto
# literal para decidir si mostrar las instrucciones de configuración del
# hook en vez de una tabla vacía.

DOTSKILLS_HOME="${DOTSKILLS_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotskills}"
LOG="$DOTSKILLS_HOME/metricas/uso_skills.log"

if [ ! -s "$LOG" ]; then
  echo "No hay registros de uso de skills todavía."
  exit 0
fi

printf '%-8s %s\n' "USOS" "SKILL"
cut -f2 "$LOG" | sort | uniq -c | sort -rn | while read -r usos skill; do
  printf '%-8s %s\n' "$usos" "$skill"
done
