#!/usr/bin/env bash
# Bucle de reproducción con intervención humana.
# Copiá este archivo, editá los pasos y ejecutalo.
# El agente ejecuta el script; el usuario sigue las indicaciones en su terminal.
#
# Uso:
#   bash hitl-loop.template.sh
#
# Dos helpers:
#   paso "<instrucción>"       → muestra la instrucción y espera Enter
#   capturar VAR "<pregunta>"  → muestra la pregunta y guarda la respuesta en VAR
#
# Al final, los valores capturados se imprimen como CLAVE=VALOR para que el agente los interprete.
#
# `capturar` imprime su valor en la terminal, donde el agente lo lee; capturá observaciones y dejá
# el inicio de sesión a cargo del usuario mediante un `paso`.
set -euo pipefail

paso() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Presioná Enter cuando termines] " _
}

capturar() {
  local var="$1" pregunta="$2" respuesta
  printf '\n>>> %s\n' "$pregunta"
  read -r -p "    > " respuesta
  printf -v "$var" '%s' "$respuesta"
}

# --- editá debajo ----------------------------------------------------------

paso "Abrí la app en http://localhost:3000 e iniciá sesión."

capturar ERROR "Hacé clic en el botón 'Exportar'. ¿Lanzó un error? (s/n)"
capturar MENSAJE_ERROR "Pegá el mensaje de error (o 'ninguno'):"

# --- editá arriba ----------------------------------------------------------

printf '\n--- Capturado ---\n'
printf 'ERROR=%s\n' "$ERROR"
printf 'MENSAJE_ERROR=%s\n' "$MENSAJE_ERROR"
