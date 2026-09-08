#!/usr/bin/env bash
set -uo pipefail

# Genera REPORT.md a partir de lo ya acumulado en DIAGNOSTICO.md: arma
# las secciones mecánicas (problema, diagnóstico, hipótesis evaluadas,
# corrección aplicada) extrayendo campos que fases anteriores ya
# escribieron — no inventa contenido nuevo.
#
# Deja "## Análisis final" con un comentario guía, sin completar: esa
# síntesis (qué pasó, por qué, qué se aprendió) es responsabilidad del
# agente, no algo que se pueda extraer mecánicamente de campos sueltos
# — ver ADR 0009.
#
# Uso: generar-reporte.sh <id>
# Imprime la ruta del REPORT.md generado, en la misma carpeta que
# DIAGNOSTICO.md.
#
# Requiere que la Fase 4 (Instrumentar) ya esté acumulada — sin eso no
# hay diagnóstico que reportar. No exige que las Fases 5/6 hayan
# cerrado: también sirve como snapshot de una investigación a medio
# terminar.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESTADO_SH="$SCRIPT_DIR/estado.sh"

err() { echo "$*" >&2; }

# Extrae "<campo>: valor" de DENTRO del registro delimitado por
# "ID: <id_h>" — no del archivo entero. Mismo helper que usan
# fases/instrumentar/scripts/{iniciar,validar}.sh. Funciona igual de
# bien contra DIAGNOSTICO.md completo aunque el mismo ID aparezca dos
# veces (una vez en la sección de Formular hipótesis, otra en la de
# Instrumentar): HIPOTESIS solo vive en la primera, SONDEO/RESULTADO/
# EVIDENCIA/VEREDICTO solo en la segunda — no hay colisión de nombres.
campo_de_registro() {
  local archivo="$1" id_h="$2" nombre="$3"
  awk -v id="ID: $id_h" -v campo="^${nombre}:" '
    $0 == id { activo=1; next }
    activo && /^ID: / { activo=0 }
    activo && $0 ~ campo { sub(campo "[[:space:]]*", ""); print; exit }
  ' "$archivo"
}

campo() {
  local archivo="$1" nombre="$2"
  grep -m1 -E "^${nombre}:" "$archivo" | sed -E "s/^${nombre}:[[:space:]]*//" || true
}

main() {
  local id="${1:-}"
  [ -n "$id" ] || { err "Uso: $0 <id>"; exit 2; }

  local dir diagnostico
  dir="$("$ESTADO_SH" dir "$id")" || exit 1
  diagnostico="$dir/DIAGNOSTICO.md"

  if ! grep -q '^## Fase: Instrumentar$' "$diagnostico"; then
    err "Error: todavía no se acumuló la Fase 4 (Instrumentar) — no hay diagnóstico confirmado que reportar."
    exit 1
  fi

  local proyecto branch commit sintoma
  proyecto="$(campo "$diagnostico" Proyecto)"
  branch="$(campo "$diagnostico" Branch)"
  commit="$(campo "$diagnostico" Commit)"
  sintoma="$(campo "$diagnostico" SINTOMA_USUARIO)"

  # IDs únicos de hipótesis, en orden — el padding a 2 dígitos (H01,
  # H02, ... H10) hace que el orden alfabético ya sea el correcto, sin
  # necesitar sort -V (no siempre disponible).
  local ids=()
  while IFS= read -r id_h; do
    [ -n "$id_h" ] && ids+=("$id_h")
  done < <(grep -oE '^ID: H[0-9]+$' "$diagnostico" | sed -E 's/^ID: //' | sort -u)

  local id_h hipotesis veredicto tabla=""
  local id_confirmada=""
  for id_h in "${ids[@]}"; do
    hipotesis="$(campo_de_registro "$diagnostico" "$id_h" HIPOTESIS)"
    # Registros que la Fase 3 dejó en blanco (mínimo 3 de 5) nunca
    # fueron una hipótesis real — instrumentar.md tampoco les genera
    # entrada. No aparecen en el reporte.
    [ -n "$hipotesis" ] || continue

    veredicto="$(campo_de_registro "$diagnostico" "$id_h" VEREDICTO)"
    [ -n "$veredicto" ] || veredicto="(sin probar)"
    tabla+="| $id_h | $hipotesis | $veredicto |"$'\n'
    [ "$veredicto" = "confirmada" ] && id_confirmada="$id_h"
  done

  local correccion="" se_puede_testear="" test_regresion="" hallazgo=""
  if grep -q '^## Fase: Corregir y testear$' "$diagnostico"; then
    correccion="$(campo "$diagnostico" CORRECCION)"
    se_puede_testear="$(campo "$diagnostico" SE_PUEDE_TESTEAR)"
    test_regresion="$(campo "$diagnostico" TEST_DE_REGRESION)"
    hallazgo="$(campo "$diagnostico" HALLAZGO)"
  fi

  local reporte="$dir/REPORT.md"
  {
    printf '# Reporte de diagnóstico: %s\n\n' "$id"
    printf -- '- **Proyecto:** %s\n' "$proyecto"
    printf -- '- **Branch:** %s\n' "$branch"
    printf -- '- **Commit:** %s\n\n' "$commit"

    printf '## Problema\n\n%s\n\n' "$sintoma"

    printf '## Diagnóstico\n\n'
    if [ -n "$id_confirmada" ]; then
      hipotesis="$(campo_de_registro "$diagnostico" "$id_confirmada" HIPOTESIS)"
      printf 'Causa confirmada (**%s**): %s\n\n' "$id_confirmada" "$hipotesis"
      printf -- '- **Sondeo:** %s\n' "$(campo_de_registro "$diagnostico" "$id_confirmada" SONDEO)"
      printf -- '- **Resultado:** %s\n' "$(campo_de_registro "$diagnostico" "$id_confirmada" RESULTADO)"
      printf -- '- **Evidencia:** `%s`\n\n' "$(campo_de_registro "$diagnostico" "$id_confirmada" EVIDENCIA)"
    else
      printf '_Todavía no hay una hipótesis confirmada._\n\n'
    fi

    printf '## Hipótesis evaluadas\n\n'
    printf '| ID | Hipótesis | Veredicto |\n'
    printf '| --- | --- | --- |\n'
    printf '%s' "$tabla"
    printf '\n'

    printf '## Corrección aplicada\n\n'
    if [ -n "$correccion" ]; then
      printf '%s\n\n' "$correccion"
      case "$se_puede_testear" in
        sí|si) printf -- '- **Verificación:** test de regresión en `%s`.\n\n' "$test_regresion" ;;
        no) printf -- '- **Verificación:** sin test de regresión — hallazgo: %s\n\n' "$hallazgo" ;;
      esac
    else
      printf '_Todavía no se acumuló la Fase 5 (Corregir y testear)._\n\n'
    fi

    printf '## Análisis final\n\n'
    printf '<!-- Completá acá un resumen de 3 a 5 líneas: qué pasó, por qué\n'
    printf 'pasó, y qué se aprendió — para quien lea esto sin haber vivido el\n'
    printf 'diagnóstico. No es un campo que se pueda extraer mecánicamente de\n'
    printf 'lo ya escrito arriba: es síntesis, no transcripción. -->\n\n'
  } > "$reporte"

  echo "$reporte"
}

main "$@"
