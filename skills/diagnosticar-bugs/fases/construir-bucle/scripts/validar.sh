#!/usr/bin/env bash
set -uo pipefail

# Valida que la fase "construir bucle" esté lista para la siguiente: dos
# cosas, no una. (1) Completitud estructural — que todos los campos
# requeridos del state.md estén completos y con un valor válido. (2)
# Verificación mecánica — re-corre el COMANDO declarado de verdad y
# confirma las 4 condiciones de salida; no confía en que el agente diga
# "ya lo probé y anda". Nunca decide si el rojo corresponde al síntoma
# real del usuario: esa es la capa semántica (transversal), no esta.
#
# Uso: validar.sh <ruta a fases/construir-bucle.md>
# Exit 0 + "READY" por stdout  si está completo y las 4 condiciones se cumplen.
# Exit 1 + "NOT_READY" por stdout, motivos por stderr, en caso contrario.
#
# Dependencias: bash, timeout. Nada externo.

UMBRAL_RAPIDO_S="${DIAGNOSTICAR_BUGS_UMBRAL_RAPIDO_S:-10}"

err() { echo "$*" >&2; }

campo() {
  local archivo="$1" nombre="$2"
  grep -m1 -E "^${nombre}:" "$archivo" | sed -E "s/^${nombre}:[[:space:]]*//"
}

# Tilda "- [ ] <id>" -> "- [x] <id>" en el state.md. Idempotente: si ya
# está tildada, no hace nada.
tildar() {
  local archivo="$1" id="$2"
  sed -i -E "s/^- \[ \] ${id}\$/- [x] ${id}/" "$archivo"
}

# Igual que tildar, pero agrega una nota aclarando que no se re-verificó
# mecánicamente (caso HITL).
tildar_confiado() {
  local archivo="$1" id="$2" nota="$3"
  sed -i -E "s/^- \[ \] ${id}\$/- [x] ${id} (${nota})/" "$archivo"
}

# --- Capa 1: completitud estructural -----------------------------------

validar_completitud() {
  local archivo="$1" motivos=0
  local sintoma metodo comando tipo_bucle ajustes

  sintoma="$(campo "$archivo" SINTOMA_USUARIO)"
  metodo="$(campo "$archivo" METODO)"
  comando="$(campo "$archivo" COMANDO)"
  tipo_bucle="$(campo "$archivo" TIPO_BUCLE)"
  ajustes="$(campo "$archivo" AJUSTES)"

  [ -n "$sintoma" ] || { err "Falta SINTOMA_USUARIO."; motivos=$((motivos + 1)); }
  [ -n "$metodo" ] || { err "Falta METODO."; motivos=$((motivos + 1)); }
  [ -n "$comando" ] || { err "Falta COMANDO."; motivos=$((motivos + 1)); }
  [ -n "$ajustes" ] || { err "Falta AJUSTES (escribí 'ninguno' si no ajustaste nada)."; motivos=$((motivos + 1)); }

  case "$tipo_bucle" in
    automatico|hitl) ;;
    "") err "Falta TIPO_BUCLE."; motivos=$((motivos + 1)) ;;
    *) err "TIPO_BUCLE inválido: '$tipo_bucle' (tiene que ser 'automatico' o 'hitl')."; motivos=$((motivos + 1)) ;;
  esac

  return "$motivos"
}

# --- Capa 2: verificación mecánica --------------------------------------

main() {
  local state_file="${1:-}"
  [ -n "$state_file" ] || { err "Uso: $0 <ruta a fases/construir-bucle.md>"; echo "NOT_READY"; exit 1; }
  [ -f "$state_file" ] || { err "No existe: $state_file"; echo "NOT_READY"; exit 1; }

  if ! validar_completitud "$state_file"; then
    echo "NOT_READY"; exit 1
  fi

  local comando tipo_bucle motivos=0
  comando="$(campo "$state_file" COMANDO)"
  tipo_bucle="$(campo "$state_file" TIPO_BUCLE)"

  if [ "$tipo_bucle" = "hitl" ]; then
    # No le pedimos a la persona que repita clicks 3 veces. Confiamos
    # en la corrida ya hecha; solo confirmamos que el comando sea
    # sintácticamente válido, y que la sección de corrida real no esté
    # vacía.
    if ! bash -n <(echo "$comando") 2>/dev/null; then
      err "El COMANDO declarado no es sintácticamente válido como bash: $comando"
      motivos=$((motivos + 1))
    fi
    if ! grep -qE '^\$ \S' "$state_file"; then
      err "No hay una corrida real pegada bajo '## Corrida real' (se espera una línea que empiece con '\$ ')."
      motivos=$((motivos + 1))
    fi
    if [ "$motivos" -eq 0 ]; then
      # HITL: "ejecutable_sin_supervision" vale por definición (la
      # intervención humana solo está permitida vía el script HITL,
      # que es justo el caso). "determinista" y "rapido" no se
      # re-verifican mecánicamente con una persona de por medio — se
      # confía en la corrida ya hecha, y queda anotado como tal.
      tildar "$state_file" "capaz_de_ponerse_en_rojo"
      tildar "$state_file" "ejecutable_sin_supervision"
      tildar_confiado "$state_file" "determinista" "confiado en la corrida HITL, no re-verificado automáticamente"
      tildar_confiado "$state_file" "rapido" "confiado en la corrida HITL, no re-verificado automáticamente"
      echo "READY"; exit 0
    else
      echo "NOT_READY"; exit 1
    fi
  fi

  # Bucle automático: re-correr de verdad, 3 veces, midiendo tiempo y
  # exit code en cada corrida.
  local codigos=() tiempos=()
  local i inicio fin codigo
  for i in 1 2 3; do
    inicio=$(date +%s)
    timeout "$((UMBRAL_RAPIDO_S * 3))" bash -c "$comando" >/dev/null 2>&1 </dev/null
    codigo=$?
    fin=$(date +%s)
    codigos+=("$codigo")
    tiempos+=("$((fin - inicio))")
    if [ "$codigo" -eq 124 ]; then
      err "Corrida $i: se colgó esperando algo (timeout a los $((UMBRAL_RAPIDO_S * 3))s). Si necesita interacción humana, marcá TIPO_BUCLE: hitl y usá scripts/hitl-loop.template.sh."
      motivos=$((motivos + 1))
    fi
  done

  # capaz_de_ponerse_en_rojo: al menos debe fallar (exit != 0) en las
  # corridas — un comando que siempre da 0 nunca detecta el bug.
  if [ "${codigos[0]}" -eq 0 ] && [ "${codigos[1]}" -eq 0 ] && [ "${codigos[2]}" -eq 0 ]; then
    err "El comando dio exit 0 en las 3 corridas — nunca se puso en rojo. Tiene que fallar (exit != 0) mientras el bug esté presente."
    motivos=$((motivos + 1))
  fi

  # determinista: las 3 corridas tienen que dar el mismo exit code.
  if [ "${codigos[0]}" != "${codigos[1]}" ] || [ "${codigos[1]}" != "${codigos[2]}" ]; then
    err "No es determinista: exit codes distintos entre corridas (${codigos[0]}, ${codigos[1]}, ${codigos[2]})."
    motivos=$((motivos + 1))
  fi

  # rapido: cada corrida individual, por debajo del umbral.
  for i in 0 1 2; do
    if [ "${tiempos[$i]}" -gt "$UMBRAL_RAPIDO_S" ]; then
      err "Corrida $((i + 1)) tardó ${tiempos[$i]}s, por encima del umbral de ${UMBRAL_RAPIDO_S}s (ajustable con DIAGNOSTICAR_BUGS_UMBRAL_RAPIDO_S)."
      motivos=$((motivos + 1))
    fi
  done

  # ejecutable_sin_supervision: ya lo garantiza que las 3 corridas
  # terminaron sin colgarse (chequeado arriba, código 124).

  if [ "$motivos" -eq 0 ]; then
    tildar "$state_file" "capaz_de_ponerse_en_rojo"
    tildar "$state_file" "determinista"
    tildar "$state_file" "rapido"
    tildar "$state_file" "ejecutable_sin_supervision"
    echo "READY"
    exit 0
  else
    echo "NOT_READY"
    exit 1
  fi
}

main "$@"
