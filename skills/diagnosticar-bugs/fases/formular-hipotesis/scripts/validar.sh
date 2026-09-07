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
# Cada hipótesis es un registro "ID: H##" + "HIPOTESIS: valor" — no
# son campos fijos: cada ronda arranca en un ID distinto (ver
# estado.sh proximo-id-hipotesis), así que este script los descubre
# dinámicamente en vez de buscar nombres hardcodeados.
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

# Extrae "<campo>: valor" de DENTRO del registro delimitado por
# "ID: <id_h>" — no del archivo entero. Necesario porque "HIPOTESIS:"
# se repite una vez por registro, a diferencia de un campo único como
# SINTOMA_USUARIO.
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

  local motivos=0 sintoma justificacion cantidad=0 id_h valor

  sintoma="$(campo "$state_file" SINTOMA_USUARIO)"
  [ -n "$sintoma" ] || { err "Falta SINTOMA_USUARIO."; motivos=$((motivos + 1)); }

  # Descubre los registros "ID: H##" presentes en el archivo (no son
  # fijos: cada ronda arranca en un ID distinto). Portable en bash 3.2
  # (sin mapfile/readarray, que son bash 4+).
  local ids=()
  while IFS= read -r id_h; do
    [ -n "$id_h" ] && ids+=("$id_h")
  done < <(grep -oE '^ID: H[0-9]+$' "$state_file" | sed -E 's/^ID: //' | sort -u)

  if [ "${#ids[@]}" -eq 0 ]; then
    err "No se encontró ningún registro de hipótesis (ID: H##) en el archivo."
    motivos=$((motivos + 1))
  fi

  for id_h in "${ids[@]}"; do
    valor="$(campo_de_registro "$state_file" "$id_h" HIPOTESIS)"
    if [ -n "$valor" ]; then
      cantidad=$((cantidad + 1))
      if ! tiene_formato_refutable "$valor"; then
        err "HIPOTESIS de $id_h no sigue el formato refutable ('Si <X> es la causa, entonces <Y>...'): '$valor'"
        motivos=$((motivos + 1))
      fi
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
