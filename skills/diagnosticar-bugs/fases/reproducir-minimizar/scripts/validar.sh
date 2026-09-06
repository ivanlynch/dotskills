#!/usr/bin/env bash
set -uo pipefail

# Valida que la fase "reproducir y minimizar" esté lista para
# acumular: dos cosas, no una. (1) Completitud estructural — que todos
# los campos requeridos del archivo de la fase estén completos, y que
# ES_MINIMO no sea una confirmación trivial ("sí"). (2) Verificación
# mecánica — re-corre el COMANDO_MINIMIZADO declarado de verdad y
# confirma que sigue reproduciendo el bug y sigue siendo determinista.
#
# Lo que este script NUNCA puede verificar: que el fallo reproducido
# sea el mismo que describe SINTOMA_USUARIO (capa semántica,
# transversal, no esta), ni que el escenario sea realmente mínimo —
# eso lo declara el agente en ES_MINIMO, con criterio del código
# puntual del bug, no algo que un script pueda enumerar solo.
#
# Uso: validar.sh <ruta a fases/reproducir-minimizar.md>
# Exit 0 + "READY" por stdout si está completo y las 2 condiciones se cumplen.
# Exit 1 + "NOT_READY" por stdout, motivos por stderr, en caso contrario.
#
# Dependencias: bash puro. Nada externo — en particular, nada de GNU
# coreutils: 'timeout' no viene en macOS (ni como 'gtimeout'), así que el
# límite de tiempo está implementado a mano más abajo (correr_con_limite).

UMBRAL_RAPIDO_S="${DIAGNOSTICAR_BUGS_UMBRAL_RAPIDO_S:-10}"
LARGO_MINIMO_ES_MINIMO="${DIAGNOSTICAR_BUGS_LARGO_MINIMO_ES_MINIMO:-15}"

err() { echo "$*" >&2; }

# Corre "bash -c <comando>" (con stdout/stderr descartados y stdin
# cerrado) en segundo plano, y lo mata si no terminó a los <segundos>.
# Deja el exit code en la variable global CORRER_CON_LIMITE_CODIGO: el
# del comando si terminó solo, o 124 (mismo código que usa GNU 'timeout')
# si hubo que matarlo. No depende de 'timeout'/'gtimeout' — solo de
# 'kill', 'wait' y 'sleep', portables entre Linux y macOS.
#
# Duplicado a propósito del homónimo en
# fases/construir-bucle/scripts/validar.sh: es la segunda vez que
# aparece esta lógica, no la tercera — no vale la pena extraerla a un
# helper compartido todavía.
correr_con_limite() {
  local segundos="$1" comando="$2"
  bash -c "$comando" >/dev/null 2>&1 </dev/null &
  local pid=$!
  local transcurrido=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$transcurrido" -ge "$segundos" ]; then
      kill -TERM "$pid" 2>/dev/null
      sleep 1
      kill -KILL "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      CORRER_CON_LIMITE_CODIGO=124
      return
    fi
    sleep 1
    transcurrido=$((transcurrido + 1))
  done
  wait "$pid" 2>/dev/null
  CORRER_CON_LIMITE_CODIGO=$?
}

campo() {
  local archivo="$1" nombre="$2"
  grep -m1 -E "^${nombre}:" "$archivo" | sed -E "s/^${nombre}:[[:space:]]*//"
}

# Tilda "- [ ] <id>" -> "- [x] <id>" en el archivo de la fase.
# Idempotente: si ya está tildada, no hace nada.
tildar() {
  local archivo="$1" id="$2"
  sed -i -E "s/^- \[ \] ${id}\$/- [x] ${id}/" "$archivo"
}

# --- Capa 1: completitud estructural -----------------------------------

validar_completitud() {
  local archivo="$1" motivos=0
  local sintoma comando recortes es_minimo

  sintoma="$(campo "$archivo" SINTOMA_USUARIO)"
  comando="$(campo "$archivo" COMANDO_MINIMIZADO)"
  recortes="$(campo "$archivo" RECORTES)"
  es_minimo="$(campo "$archivo" ES_MINIMO)"

  [ -n "$sintoma" ] || { err "Falta SINTOMA_USUARIO."; motivos=$((motivos + 1)); }
  [ -n "$comando" ] || { err "Falta COMANDO_MINIMIZADO."; motivos=$((motivos + 1)); }
  [ -n "$recortes" ] || { err "Falta RECORTES (escribí 'ninguno' si no recortaste nada)."; motivos=$((motivos + 1)); }

  if [ -z "$es_minimo" ]; then
    err "Falta ES_MINIMO."
    motivos=$((motivos + 1))
  elif [ "${#es_minimo}" -lt "$LARGO_MINIMO_ES_MINIMO" ]; then
    err "ES_MINIMO es demasiado corto ('$es_minimo') — no alcanza con 'sí', confirmá explícitamente qué probaste sacar."
    motivos=$((motivos + 1))
  fi

  return "$motivos"
}

# --- Capa 2: verificación mecánica --------------------------------------

main() {
  local state_file="${1:-}"
  [ -n "$state_file" ] || { err "Uso: $0 <ruta a fases/reproducir-minimizar.md>"; echo "NOT_READY"; exit 1; }
  [ -f "$state_file" ] || { err "No existe: $state_file"; echo "NOT_READY"; exit 1; }

  if ! validar_completitud "$state_file"; then
    echo "NOT_READY"; exit 1
  fi

  local comando motivos=0
  comando="$(campo "$state_file" COMANDO_MINIMIZADO)"

  # Re-correr de verdad, 3 veces, midiendo tiempo y exit code en cada
  # corrida — mismo criterio que Fase 1, sobre el comando ya recortado.
  local codigos=() tiempos=()
  local i inicio fin codigo
  for i in 1 2 3; do
    inicio=$(date +%s)
    correr_con_limite "$((UMBRAL_RAPIDO_S * 3))" "$comando"
    codigo="$CORRER_CON_LIMITE_CODIGO"
    fin=$(date +%s)
    codigos+=("$codigo")
    tiempos+=("$((fin - inicio))")
    if [ "$codigo" -eq 124 ]; then
      err "Corrida $i: se colgó esperando algo (timeout a los $((UMBRAL_RAPIDO_S * 3))s)."
      motivos=$((motivos + 1))
    fi
  done

  # reproduce_el_bug: al menos debe fallar (exit != 0) en las corridas
  # — un comando que siempre da 0 ya no reproduce nada.
  if [ "${codigos[0]}" -eq 0 ] && [ "${codigos[1]}" -eq 0 ] && [ "${codigos[2]}" -eq 0 ]; then
    err "El comando dio exit 0 en las 3 corridas — no reproduce el bug."
    motivos=$((motivos + 1))
  fi

  # determinista: las 3 corridas tienen que dar el mismo exit code.
  if [ "${codigos[0]}" != "${codigos[1]}" ] || [ "${codigos[1]}" != "${codigos[2]}" ]; then
    err "No es determinista: exit codes distintos entre corridas (${codigos[0]}, ${codigos[1]}, ${codigos[2]})."
    motivos=$((motivos + 1))
  fi

  if [ "$motivos" -eq 0 ]; then
    tildar "$state_file" "reproduce_el_bug"
    tildar "$state_file" "determinista"
    echo "READY"
    exit 0
  else
    echo "NOT_READY"
    exit 1
  fi
}

main "$@"
