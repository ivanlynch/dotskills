#!/usr/bin/env bash
set -uo pipefail

# Valida mecánicamente 3 de los 5 ítems del checklist de Limpiar (ver
# INSTRUCCIONES.md): que el COMANDO original de la Fase 1 ya no
# reproduzca el bug, que la Fase 5 haya quedado en un estado consistente
# (test de regresión o HALLAZGO documentado, no los dos ni ninguno), y
# que no quede instrumentación [DEBUG-...] en el repo. Los otros dos
# ítems (prototipos descartables, hipótesis en el commit/PR) no se
# pueden verificar mecánicamente — quedan al criterio del agente.
#
# Uso: validar.sh <id>
# Corré desde la raíz del proyecto (mismo supuesto que el COMANDO de la
# Fase 1): re-corre ese COMANDO y busca [DEBUG-...] en el directorio
# actual.
# Exit 0 + "READY" por stdout si las 3 condiciones mecánicas se cumplen.
# Exit 1 + "NOT_READY" por stdout, motivos por stderr, en caso contrario.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESTADO_SH="$SCRIPT_DIR/../../../scripts/estado.sh"

err() { echo "$*" >&2; }

main() {
  local id="${1:-}"
  [ -n "$id" ] || { err "Uso: $0 <id>"; echo "NOT_READY"; exit 1; }

  # Falla temprano y con mensaje claro si el id no existe, en vez de que
  # los "campo" de abajo devuelvan vacío en silencio.
  "$ESTADO_SH" dir "$id" >/dev/null || { echo "NOT_READY"; exit 1; }

  local motivos=0

  # --- 1. El COMANDO original de la Fase 1 ya no reproduce el bug ---
  local comando tipo_bucle
  comando="$("$ESTADO_SH" campo "$id" COMANDO)"
  tipo_bucle="$("$ESTADO_SH" campo "$id" TIPO_BUCLE)"

  if [ -z "$comando" ]; then
    err "No se encontró COMANDO en DIAGNOSTICO.md — ¿se acumuló la Fase 1?"
    motivos=$((motivos + 1))
  elif [ "$tipo_bucle" = "hitl" ]; then
    err "Aviso: TIPO_BUCLE es 'hitl', no se puede re-correr el COMANDO sin supervisión — confirmá vos mismo que ya no reproduce (no cuenta como motivo de NOT_READY)."
  elif bash -c "$comando" >/dev/null 2>&1; then
    : # exit 0 = ya no reproduce (verde) — bien
  else
    err "El COMANDO original ('$comando') todavía da rojo — el bug sigue reproduciéndose."
    motivos=$((motivos + 1))
  fi

  # --- 2. Fase 5 quedó en un estado consistente ---
  local se_puede test_regresion hallazgo
  se_puede="$("$ESTADO_SH" campo "$id" SE_PUEDE_TESTEAR)"
  test_regresion="$("$ESTADO_SH" campo "$id" TEST_DE_REGRESION)"
  hallazgo="$("$ESTADO_SH" campo "$id" HALLAZGO)"

  case "$se_puede" in
    sí|si)
      [ -n "$test_regresion" ] || { err "SE_PUEDE_TESTEAR es 'sí' pero falta TEST_DE_REGRESION en la Fase 5."; motivos=$((motivos + 1)); }
      [ -z "$hallazgo" ] || { err "SE_PUEDE_TESTEAR es 'sí' pero también hay un HALLAZGO completado — la Fase 5 tiene que llenar uno de los dos, no los dos."; motivos=$((motivos + 1)); }
      ;;
    no)
      [ -n "$hallazgo" ] || { err "SE_PUEDE_TESTEAR es 'no' pero falta HALLAZGO en la Fase 5."; motivos=$((motivos + 1)); }
      [ -z "$test_regresion" ] || { err "SE_PUEDE_TESTEAR es 'no' pero también hay un TEST_DE_REGRESION completado — la Fase 5 tiene que llenar uno de los dos, no los dos."; motivos=$((motivos + 1)); }
      ;;
    *)
      err "No se encontró SE_PUEDE_TESTEAR en DIAGNOSTICO.md — ¿se acumuló la Fase 5?"
      motivos=$((motivos + 1))
      ;;
  esac

  # --- 3. No quedó instrumentación [DEBUG-...] en el repo ---
  local encontrados
  encontrados="$(grep -rn '\[DEBUG-' --exclude-dir=.git . 2>/dev/null || true)"
  if [ -n "$encontrados" ]; then
    err "Todavía queda instrumentación [DEBUG-...] sin eliminar:"
    err "$encontrados"
    motivos=$((motivos + 1))
  fi

  if [ "$motivos" -eq 0 ]; then
    echo "READY"
    exit 0
  else
    echo "NOT_READY"
    exit 1
  fi
}

main "$@"
