#!/usr/bin/env bash
set -uo pipefail

# Valida la ENTRADA VIGENTE de la fase "instrumentar" — la hipótesis
# de menor ID que todavía no tiene VEREDICTO ("confirmada" o
# "descartada"). No hace falta ningún campo aparte que la señale: este
# script la calcula solo, mirando qué registros ("ID:"/"SONDEO:"/
# "RESULTADO:"/"VEREDICTO:") ya existen en el archivo.
#
# No valida que toda la fase haya terminado — Instrumentar es un loop,
# puede pasar por acá una vez por cada hipótesis. Es INSTRUCCIONES.md
# (no este script) quien decide si hay que seguir probando, volver a
# la Fase 3, o avanzar a la Fase 5, según el veredicto de la vigente.
#
# Si TODAS las hipótesis conocidas ya tienen veredicto y ninguna es
# "confirmada", no hay ninguna "vigente" que validar — eso es
# agotamiento, y este script lo reporta como motivo de NOT_READY en
# vez de fallar de forma confusa.
#
# Nunca puede verificar que el sondeo sea el correcto ni que el
# resultado esté bien interpretado — eso es criterio del agente.
#
# Uso: validar.sh <ruta a fases/instrumentar.md>
# Exit 0 + "READY" por stdout si la entrada vigente está completa.
# Exit 1 + "NOT_READY" por stdout, motivos por stderr, en caso contrario.

err() { echo "$*" >&2; }

campo() {
  local archivo="$1" nombre="$2"
  grep -m1 -E "^${nombre}:" "$archivo" | sed -E "s/^${nombre}:[[:space:]]*//"
}

# Extrae "<campo>: valor" de DENTRO del registro delimitado por
# "ID: <id_h>" — no del archivo entero. Necesario porque "SONDEO:",
# "RESULTADO:" y "VEREDICTO:" se repiten una vez por registro.
campo_de_registro() {
  local archivo="$1" id_h="$2" nombre="$3"
  awk -v id="ID: $id_h" -v campo="^${nombre}:" '
    $0 == id { activo=1; next }
    activo && /^ID: / { activo=0 }
    activo && $0 ~ campo { sub(campo "[[:space:]]*", ""); print; exit }
  ' "$archivo"
}

# Tilda "- [ ] <id>" -> "- [x] <id>" en el archivo de la fase.
# Idempotente: si ya está tildada, no hace nada.
tildar() {
  local archivo="$1" id="$2"
  sed -i -E "s/^- \[ \] ${id}\$/- [x] ${id}/" "$archivo"
}

main() {
  local state_file="${1:-}"
  [ -n "$state_file" ] || { err "Uso: $0 <ruta a fases/instrumentar.md>"; echo "NOT_READY"; exit 1; }
  [ -f "$state_file" ] || { err "No existe: $state_file"; echo "NOT_READY"; exit 1; }

  local motivos=0 sintoma id_h veredicto sondeo resultado actual=""

  sintoma="$(campo "$state_file" SINTOMA_USUARIO)"
  [ -n "$sintoma" ] || { err "Falta SINTOMA_USUARIO."; motivos=$((motivos + 1)); }

  # Descubre los registros de hipótesis presentes en el archivo (no
  # son fijos: dependen de cuántas generó la Fase 3, en una o más
  # rondas).
  local ids=()
  while IFS= read -r id_h; do
    [ -n "$id_h" ] && ids+=("$id_h")
  done < <(grep -oE '^ID: H[0-9]+$' "$state_file" | sed -E 's/^ID: //' | sort -u)

  if [ "${#ids[@]}" -eq 0 ]; then
    err "No se encontró ningún registro de hipótesis (ID: H##) en el archivo."
    motivos=$((motivos + 1))
  fi

  # La vigente: la de menor ID sin veredicto todavía. De paso, si
  # alguna ya está "confirmada", lo recordamos: cambia qué significa
  # que no quede ninguna vigente (éxito, no agotamiento).
  local hay_confirmada=0
  for id_h in "${ids[@]}"; do
    veredicto="$(campo_de_registro "$state_file" "$id_h" VEREDICTO)"
    case "$veredicto" in
      confirmada) hay_confirmada=1 ;;
      descartada) ;;
      *) [ -z "$actual" ] && actual="$id_h" ;;
    esac
  done

  if [ "$hay_confirmada" -eq 1 ]; then
    : # Éxito: ya hay una hipótesis confirmada. No importa si quedan
      # otras sin tocar (iniciar.sh les crea el registro a todas de
      # entrada) — encontrada la causa, no hay nada más que validar.
  elif [ -n "$actual" ]; then
    sondeo="$(campo_de_registro "$state_file" "$actual" SONDEO)"
    resultado="$(campo_de_registro "$state_file" "$actual" RESULTADO)"
    veredicto="$(campo_de_registro "$state_file" "$actual" VEREDICTO)"

    [ -n "$sondeo" ] || { err "Falta SONDEO del registro $actual."; motivos=$((motivos + 1)); }
    [ -n "$resultado" ] || { err "Falta RESULTADO del registro $actual."; motivos=$((motivos + 1)); }
    case "$veredicto" in
      confirmada|descartada) ;;
      "") err "Falta VEREDICTO del registro $actual."; motivos=$((motivos + 1)) ;;
      *) err "VEREDICTO del registro $actual es inválido: '$veredicto' (tiene que ser 'confirmada' o 'descartada')."; motivos=$((motivos + 1)) ;;
    esac
  elif [ "${#ids[@]}" -gt 0 ]; then
    err "Todas las hipótesis conocidas ya tienen veredicto y ninguna quedó 'confirmada' — volvé a la Fase 3 a generar una ronda nueva."
    motivos=$((motivos + 1))
  fi

  if [ "$motivos" -eq 0 ]; then
    tildar "$state_file" "entrada_completa"
    echo "READY"
    exit 0
  else
    echo "NOT_READY"
    exit 1
  fi
}

main "$@"
