#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/../crear_spec.sh"

echo "Ejecutando tests para crear_spec.sh..."

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

crear_prd_fixture() {
  local ruta="$1" estado="$2" con_rfs="$3"
  {
    printf '# PRD: Invitaciones a equipos\n\n'
    printf '**Fecha:** 2026-08-15\n'
    printf '**Estado:** %s\n\n' "$estado"
    printf -- '---\n\n'
    if [ "$con_rfs" = "si" ]; then
      printf '#### RF001: Crear invitación\n'
      printf 'Un administrador puede crear una invitación indicando un email y un rol.\n\n'
      printf '#### RF002: Aceptar invitación\n'
      printf 'El destinatario puede aceptar una invitación válida.\n'
    fi
  } > "$ruta"
}

if "$TARGET_SCRIPT" > /dev/null 2>&1; then
  echo "TEST FAIL: Debería fallar sin subcomando." >&2
  exit 1
else
  echo "PASS: Falla correctamente sin subcomando."
fi

if "$TARGET_SCRIPT" init "${TMP_DIR}/no-existe.md" > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar si el PRD no existe." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente si el PRD no existe."
fi

PRD_BORRADOR="${TMP_DIR}/prd-borrador.md"
crear_prd_fixture "$PRD_BORRADOR" "Borrador" "si"
if "$TARGET_SCRIPT" init "$PRD_BORRADOR" > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar si el PRD no está en Estado Completo." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente con un PRD en Borrador."
fi

PRD_SIN_RF="${TMP_DIR}/prd-sin-rf.md"
crear_prd_fixture "$PRD_SIN_RF" "Completo" "no"
if "$TARGET_SCRIPT" init "$PRD_SIN_RF" > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar si el PRD no tiene ningún RF00N." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente con un PRD sin requerimientos."
fi

PRD_OK="${TMP_DIR}/prd-ok.md"
crear_prd_fixture "$PRD_OK" "Completo" "si"
SPEC_OUTPUT="${TMP_DIR}/spec.md"
INIT_STDOUT=$("$TARGET_SCRIPT" init "$PRD_OK" "$SPEC_OUTPUT")

if [ ! -f "$SPEC_OUTPUT" ]; then
  echo "TEST FAIL: El archivo spec.md no fue creado." >&2
  exit 1
fi
if ! grep -q "^# Spec: Invitaciones a equipos$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: El título no fue tomado correctamente del PRD." >&2
  exit 1
fi
if ! grep -qF "**PRD:** ${PRD_OK}" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: La ruta del PRD no quedó registrada en el spec." >&2
  exit 1
fi
echo "PASS: 'init' crea el spec con título y referencia al PRD."

if ! grep -q "^## RF001: Crear invitación\$" "$SPEC_OUTPUT" || ! grep -q "^## RF002: Aceptar invitación\$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: 'init' no generó una sección por cada RF del PRD." >&2
  exit 1
fi
if ! grep -qF '{{ESCENARIOS_RF001}}' "$SPEC_OUTPUT" || ! grep -qF '{{ESCENARIOS_RF002}}' "$SPEC_OUTPUT"; then
  echo "TEST FAIL: 'init' no dejó un placeholder de escenarios por cada sección RF." >&2
  exit 1
fi
echo "PASS: 'init' scaffoldea una sección con placeholder propio por cada RF del PRD."

if ! printf '%s' "$INIT_STDOUT" | grep -q "^RF001: Crear invitación$" || ! printf '%s' "$INIT_STDOUT" | grep -q "^RF002: Aceptar invitación$"; then
  echo "TEST FAIL: 'init' no imprimió la agenda de RF-IDs a especificar." >&2
  exit 1
fi
echo "PASS: 'init' imprime por stdout la lista ordenada de RF-IDs a especificar."

(
  cd "$TMP_DIR"
  mkdir -p sinruta
  crear_prd_fixture "sinruta/prd.md" "Completo" "si"
  "$TARGET_SCRIPT" init "sinruta/prd.md" > /dev/null
  if [ ! -f "sinruta/spec.md" ]; then
    echo "TEST FAIL: sin ruta_salida, 'init' debería guardar spec.md junto al PRD." >&2
    exit 1
  fi
)
echo "PASS: 'init' sin ruta_salida usa por defecto el mismo directorio del PRD."

if "$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF999 "x" "y" > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --escenario' debería rechazar un RF-ID que no existe en el spec." >&2
  exit 1
else
  echo "PASS: 'add --escenario' rechaza un RF-ID inexistente."
fi

"$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF001 "Alta exitosa" "Dado que el usuario es administrador
Cuando crea una invitación con email y rol válidos
Entonces el sistema crea la invitación" > /dev/null

if ! grep -q "^### RF001E001: Alta exitosa\$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: El escenario no quedó registrado bajo RF001 con el ID RF001E001 esperado." >&2
  exit 1
fi
echo "PASS: 'add --escenario' inserta el encabezado (con ID RF001E00N autoasignado) y el bloque Gherkin del escenario."

if "$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF002 --cerrar-lista > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --escenario --cerrar-lista' no debería aceptarse sin ningún escenario cargado antes." >&2
  exit 1
else
  echo "PASS: 'add --escenario --cerrar-lista' rechaza cerrar una sección sin escenarios."
fi

"$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF001 "Email sin rol" "Dado que el usuario es administrador
Cuando intenta crear una invitación sin indicar un rol
Entonces el sistema rechaza la solicitud" --cerrar-lista > /dev/null

if grep -qF '{{ESCENARIOS_RF001}}' "$SPEC_OUTPUT"; then
  echo "TEST FAIL: --cerrar-lista debería haber eliminado el marcador de RF001." >&2
  exit 1
fi
if ! grep -q "^### RF001E001: Alta exitosa\$" "$SPEC_OUTPUT" || ! grep -q "^### RF001E002: Email sin rol\$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: Ambos escenarios de RF001 deberían seguir presentes, con IDs RF001E001 y RF001E002 en orden." >&2
  exit 1
fi
echo "PASS: 'add --escenario --cerrar-lista' conserva los escenarios previos (con IDs secuenciales) y cierra solo esa sección."

if ! grep -q "^$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: no hay ninguna línea en blanco en el spec (¿los escenarios quedaron pegados?)." >&2
  exit 1
fi
BLANK_ANTES_RF001E002=$(grep -n "^### RF001E002: " "$SPEC_OUTPUT" | head -1 | cut -d: -f1)
BLANK_ANTES_RF001E002=$((BLANK_ANTES_RF001E002 - 1))
if [ -n "$(sed -n "${BLANK_ANTES_RF001E002}p" "$SPEC_OUTPUT")" ]; then
  echo "TEST FAIL: debería haber una línea en blanco antes de cada encabezado de escenario." >&2
  exit 1
fi
echo "PASS: hay una línea en blanco antes de cada encabezado de escenario (no quedan pegados)."

if ! grep -qF '{{ESCENARIOS_RF002}}' "$SPEC_OUTPUT"; then
  echo "TEST FAIL: cerrar la sección RF001 no debería afectar el placeholder de RF002." >&2
  exit 1
fi
echo "PASS: cerrar una sección no cierra ni afecta el placeholder de otra sección."

if "$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF001 "otro escenario más" "Dado ..." > /dev/null 2>&1; then
  echo "TEST FAIL: No debería permitir agregar escenarios a una sección ya cerrada." >&2
  exit 1
else
  echo "PASS: 'add --escenario' rechaza agregar a una sección ya cerrada."
fi

if "$TARGET_SCRIPT" check "$SPEC_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería fallar mientras quede una sección sin cerrar (RF002)." >&2
  exit 1
else
  echo "PASS: 'check' detecta secciones sin cerrar."
fi

"$TARGET_SCRIPT" add "$SPEC_OUTPUT" --escenario RF002 "Aceptación exitosa" "Dado un token válido
Cuando el destinatario acepta la invitación
Entonces pasa a formar parte del equipo" --cerrar-lista > /dev/null

if ! grep -q "^### RF002E001: Aceptación exitosa\$" "$SPEC_OUTPUT"; then
  echo "TEST FAIL: la numeración de escenarios debería ser propia de cada sección (RF002E001, no continuar desde RF001E002)." >&2
  exit 1
fi
echo "PASS: la numeración de escenarios está scopeada por sección RF, no es un contador global."

if ! "$TARGET_SCRIPT" check "$SPEC_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería pasar una vez cerradas todas las secciones." >&2
  exit 1
fi
echo "PASS: 'check' confirma que no quedan placeholders pendientes."

SPEC_SIN_CERRAR="${TMP_DIR}/spec-sin-cerrar.md"
"$TARGET_SCRIPT" init "$PRD_OK" "$SPEC_SIN_CERRAR" > /dev/null
if "$TARGET_SCRIPT" aprobar "$SPEC_SIN_CERRAR" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' no debería permitirse mientras queden placeholders pendientes." >&2
  exit 1
else
  echo "PASS: 'aprobar' rechaza un spec con placeholders pendientes."
fi

if ! "$TARGET_SCRIPT" aprobar "$SPEC_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' debería aceptarse una vez que 'check' está en OK." >&2
  exit 1
fi
if ! grep -q '\*\*Estado:\*\* Completo' "$SPEC_OUTPUT"; then
  echo "TEST FAIL: 'aprobar' debería haber cambiado el Estado a Completo." >&2
  exit 1
fi
if grep -q '\*\*Estado:\*\* Borrador' "$SPEC_OUTPUT"; then
  echo "TEST FAIL: 'aprobar' no debería dejar el Estado en Borrador." >&2
  exit 1
fi
echo "PASS: 'aprobar' cambia el Estado de Borrador a Completo cuando check está en OK."

if "$TARGET_SCRIPT" aprobar "$SPEC_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' no debería poder correrse dos veces sobre el mismo spec." >&2
  exit 1
else
  echo "PASS: 'aprobar' rechaza aprobar un spec que ya no está en Borrador."
fi

echo "Todos los tests pasaron correctamente."
