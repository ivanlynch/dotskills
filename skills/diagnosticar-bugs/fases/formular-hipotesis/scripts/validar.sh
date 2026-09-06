#!/usr/bin/env bash
set -uo pipefail

# Valida que la fase "formular hipótesis" esté lista para acumular. A
# diferencia de las Fases 1 y 2, acá no hay un comando que re-correr —
# formular hipótesis es puro razonamiento, sin señal roja/verde. Este
# script solo valida completitud y que cada hipótesis siga el formato
# refutable exigido ("Si X es la causa, entonces Y..."). Nunca puede
# verificar que una hipótesis sea buena o esté bien ordenada — eso
# queda para el criterio del agente y para cuando el usuario revisa la
# lista (ver INSTRUCCIONES.md).
#
# Uso: validar.sh <ruta a fases/formular-hipotesis.md>
# Exit 0 + "READY" por stdout si está completo. Exit 1 + "NOT_READY"
# por stdout, motivos por stderr, en caso contrario.

LARGO_MINIMO_JUSTIFICACION="${DIAGNOSTICAR_BUGS_LARGO_MINIMO_JUSTIFICACION:-15}"

err() { echo "$*" >&2; }

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

# Chequeo laxo de formato: la hipótesis tiene que mencionar "si" y
# "entonces" (sin importar mayúsculas), como proxy de que sigue la
# forma "Si <X> es la causa, entonces <Y>...". No puede verificar que
# la predicción tenga sentido — solo que existe una con esa forma.
tiene_formato_refutable() {
  printf '%s' "$1" | grep -qiE 'si .*entonces'
}

main() {
  local state_file="${1:-}"
  [ -n "$state_file" ] || { err "Uso: $0 <ruta a fases/formular-hipotesis.md>"; echo "NOT_READY"; exit 1; }
  [ -f "$state_file" ] || { err "No existe: $state_file"; echo "NOT_READY"; exit 1; }

  local motivos=0 sintoma justificacion cantidad=0 i
  local -a hipotesis

  sintoma="$(campo "$state_file" SINTOMA_USUARIO)"
  [ -n "$sintoma" ] || { err "Falta SINTOMA_USUARIO."; motivos=$((motivos + 1)); }

  for i in 1 2 3 4 5; do
    hipotesis[$i]="$(campo "$state_file" "HIPOTESIS_$i")"
    [ -n "${hipotesis[$i]}" ] && cantidad=$((cantidad + 1))
  done

  if [ "$cantidad" -eq 0 ]; then
    err "No hay ninguna hipótesis — HIPOTESIS_1 tiene que estar completa."
    motivos=$((motivos + 1))
  fi

  for i in 1 2 3 4 5; do
    if [ -n "${hipotesis[$i]}" ] && ! tiene_formato_refutable "${hipotesis[$i]}"; then
      err "HIPOTESIS_$i no sigue el formato refutable ('Si <X> es la causa, entonces <Y>...'): '${hipotesis[$i]}'"
      motivos=$((motivos + 1))
    fi
  done

  justificacion="$(campo "$state_file" JUSTIFICACION_MENOS_DE_3)"
  if [ "$cantidad" -lt 3 ]; then
    if [ -z "$justificacion" ] || [ "$justificacion" = "no aplica" ]; then
      err "Hay menos de 3 hipótesis ($cantidad) y falta JUSTIFICACION_MENOS_DE_3 explicando por qué."
      motivos=$((motivos + 1))
    elif [ "${#justificacion}" -lt "$LARGO_MINIMO_JUSTIFICACION" ]; then
      err "JUSTIFICACION_MENOS_DE_3 es demasiado corta ('$justificacion')."
      motivos=$((motivos + 1))
    fi
  else
    [ -n "$justificacion" ] || { err "Falta JUSTIFICACION_MENOS_DE_3 (escribí 'no aplica' si generaste 3 o más)."; motivos=$((motivos + 1)); }
  fi

  if [ "$motivos" -eq 0 ]; then
    tildar "$state_file" "cantidad_valida"
    tildar "$state_file" "formato_valido"
    echo "READY"
    exit 0
  else
    echo "NOT_READY"
    exit 1
  fi
}

main "$@"
