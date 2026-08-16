#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/../crear_plan.sh"

echo "Ejecutando tests para crear_plan.sh..."

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

crear_spec_fixture() {
  local ruta="$1" estado="$2" con_escenarios="$3"
  {
    printf '# Spec: Invitaciones a equipos\n\n'
    printf '**Fecha:** 2026-08-15\n'
    printf '**Estado:** %s\n' "$estado"
    printf '**PRD:** /tmp/prd.md\n\n'
    printf -- '---\n\n'
    if [ "$con_escenarios" = "si" ]; then
      printf '## RF001: Crear invitación\n\n'
      printf '### RF001E001: Alta exitosa\n'
      printf 'Dado que el usuario es admin\nCuando crea una invitación\nEntonces el sistema la crea\n\n'
      printf '### RF001E002: Email sin rol\n'
      printf 'Dado que el usuario es admin\nCuando intenta crear sin rol\nEntonces el sistema rechaza\n\n'
      printf '## RF002: Aceptar invitación\n\n'
      printf '### RF002E001: Aceptación exitosa\n'
      printf 'Dado un token válido\nCuando el usuario acepta\nEntonces pasa a formar parte del equipo\n'
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
  echo "TEST FAIL: 'init' debería fallar si la spec no existe." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente si la spec no existe."
fi

SPEC_BORRADOR="${TMP_DIR}/spec-borrador.md"
crear_spec_fixture "$SPEC_BORRADOR" "Borrador" "si"
if "$TARGET_SCRIPT" init "$SPEC_BORRADOR" > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar si la spec no está en Estado Completo." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente con una spec en Borrador."
fi

SPEC_SIN_ESC="${TMP_DIR}/spec-sin-escenarios.md"
crear_spec_fixture "$SPEC_SIN_ESC" "Completo" "no"
if "$TARGET_SCRIPT" init "$SPEC_SIN_ESC" > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar si la spec no tiene ningún escenario." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente con una spec sin escenarios."
fi

SPEC_OK="${TMP_DIR}/spec-ok.md"
crear_spec_fixture "$SPEC_OK" "Completo" "si"
PLAN_OUTPUT="${TMP_DIR}/plan.md"
INIT_STDOUT=$("$TARGET_SCRIPT" init "$SPEC_OK" "$PLAN_OUTPUT")

if [ ! -f "$PLAN_OUTPUT" ]; then
  echo "TEST FAIL: El archivo plan.md no fue creado." >&2
  exit 1
fi
if ! grep -q "^# Plan: Invitaciones a equipos$" "$PLAN_OUTPUT"; then
  echo "TEST FAIL: El título no fue tomado correctamente de la spec." >&2
  exit 1
fi
if ! grep -qF "**Spec:** ${SPEC_OK}" "$PLAN_OUTPUT"; then
  echo "TEST FAIL: La ruta de la spec no quedó registrada en el plan." >&2
  exit 1
fi
echo "PASS: 'init' crea el plan con título y referencia a la spec."

if ! printf '%s' "$INIT_STDOUT" | grep -q "^RF001E001: Alta exitosa$" \
  || ! printf '%s' "$INIT_STDOUT" | grep -q "^RF001E002: Email sin rol$" \
  || ! printf '%s' "$INIT_STDOUT" | grep -q "^RF002E001: Aceptación exitosa$"; then
  echo "TEST FAIL: 'init' no imprimió la agenda completa de escenarios a cubrir." >&2
  exit 1
fi
echo "PASS: 'init' imprime por stdout la lista ordenada de escenarios a cubrir."

(
  cd "$TMP_DIR"
  mkdir -p sinruta
  crear_spec_fixture "sinruta/spec.md" "Completo" "si"
  "$TARGET_SCRIPT" init "sinruta/spec.md" > /dev/null
  if [ ! -f "sinruta/plan.md" ]; then
    echo "TEST FAIL: sin ruta_salida, 'init' debería guardar plan.md junto a la spec." >&2
    exit 1
  fi
)
echo "PASS: 'init' sin ruta_salida usa por defecto el mismo directorio de la spec."

if "$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "x" "y" --verificacion "z" --cubre RF999E999 > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --tarea --cubre' debería rechazar un escenario que no existe en la spec." >&2
  exit 1
else
  echo "PASS: 'add --tarea --cubre' rechaza un escenario inexistente en la spec."
fi

if "$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "x" "y" --verificacion "z" --cubre RF001E001 --depende-de T999 > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --tarea --depende-de' debería rechazar una tarea inexistente." >&2
  exit 1
else
  echo "PASS: 'add --tarea --depende-de' rechaza una tarea inexistente."
fi

if "$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "sin verificación" "descripción" --cubre RF001E001 > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --tarea' debería exigir --verificacion." >&2
  exit 1
else
  echo "PASS: 'add --tarea' rechaza una tarea sin --verificacion."
fi

if "$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "sin cubre" "descripción" --verificacion "algo" > /dev/null 2>&1; then
  echo "TEST FAIL: 'add --tarea' debería exigir --cubre." >&2
  exit 1
else
  echo "PASS: 'add --tarea' rechaza una tarea sin --cubre."
fi

"$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "Crear endpoint de invitación" "Implementa POST /invitations" \
  --verificacion "Tests de RF001E001 y RF001E002 en verde" --cubre RF001E001 RF001E002 > /dev/null

if ! grep -q "^### T001: Crear endpoint de invitación\$" "$PLAN_OUTPUT"; then
  echo "TEST FAIL: La tarea no quedó registrada con el ID T001 esperado." >&2
  exit 1
fi
if ! grep -qF '**Depende de:** Ninguna' "$PLAN_OUTPUT"; then
  echo "TEST FAIL: Una tarea sin --depende-de debería quedar con 'Ninguna'." >&2
  exit 1
fi
echo "PASS: 'add --tarea' asigna el ID T001 e inserta el bloque completo."

if "$TARGET_SCRIPT" check "$PLAN_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería fallar mientras la lista de tareas siga abierta." >&2
  exit 1
else
  echo "PASS: 'check' detecta que la lista de tareas sigue abierta."
fi

"$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea --cerrar-lista > /dev/null

if "$TARGET_SCRIPT" check "$PLAN_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería fallar mientras falte cubrir RF002E001." >&2
  exit 1
else
  echo "PASS: 'check' detecta un escenario de la spec sin ninguna tarea que lo cubra."
fi

if "$TARGET_SCRIPT" add "$PLAN_OUTPUT" --tarea "no debería poder" "agregarse" --verificacion "z" --cubre RF002E001 > /dev/null 2>&1; then
  echo "TEST FAIL: No debería permitir agregar tareas a una lista ya cerrada." >&2
  exit 1
else
  echo "PASS: 'add --tarea' rechaza agregar a una lista ya cerrada."
fi

PLAN2_OUTPUT="${TMP_DIR}/plan2.md"
"$TARGET_SCRIPT" init "$SPEC_OK" "$PLAN2_OUTPUT" > /dev/null
"$TARGET_SCRIPT" add "$PLAN2_OUTPUT" --tarea "Crear endpoint de invitación" "Implementa POST /invitations" \
  --verificacion "Tests de RF001E001 y RF001E002 en verde" --cubre RF001E001 RF001E002 > /dev/null
"$TARGET_SCRIPT" add "$PLAN2_OUTPUT" --tarea "Crear endpoint de aceptación" "Implementa POST /invitations/:token/accept" \
  --verificacion "Test de RF002E001 en verde" --depende-de T001 --cubre RF002E001 --cerrar-lista > /dev/null

if ! grep -q "^### T002: Crear endpoint de aceptación\$" "$PLAN2_OUTPUT"; then
  echo "TEST FAIL: La segunda tarea no quedó registrada con el ID T002 esperado." >&2
  exit 1
fi
if ! grep -qF '**Depende de:** T001' "$PLAN2_OUTPUT"; then
  echo "TEST FAIL: La dependencia declarada no quedó registrada." >&2
  exit 1
fi
echo "PASS: 'add --tarea' asigna IDs T00N incrementales y registra dependencias."

if ! "$TARGET_SCRIPT" check "$PLAN2_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería pasar una vez que todos los escenarios están cubiertos." >&2
  exit 1
fi
echo "PASS: 'check' confirma que todos los escenarios de la spec quedaron cubiertos."

if "$TARGET_SCRIPT" aprobar "$PLAN_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' no debería permitirse mientras falte cobertura (RF002E001)." >&2
  exit 1
else
  echo "PASS: 'aprobar' rechaza un plan con escenarios sin cubrir."
fi

if ! "$TARGET_SCRIPT" aprobar "$PLAN2_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' debería aceptarse una vez que 'check' está en OK." >&2
  exit 1
fi
if ! grep -q '\*\*Estado:\*\* Completo' "$PLAN2_OUTPUT"; then
  echo "TEST FAIL: 'aprobar' debería haber cambiado el Estado a Completo." >&2
  exit 1
fi
if grep -q '\*\*Estado:\*\* Borrador' "$PLAN2_OUTPUT"; then
  echo "TEST FAIL: 'aprobar' no debería dejar el Estado en Borrador." >&2
  exit 1
fi
echo "PASS: 'aprobar' cambia el Estado de Borrador a Completo cuando check está en OK."

if "$TARGET_SCRIPT" aprobar "$PLAN2_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'aprobar' no debería poder correrse dos veces sobre el mismo plan." >&2
  exit 1
else
  echo "PASS: 'aprobar' rechaza aprobar un plan que ya no está en Borrador."
fi

echo "Todos los tests pasaron correctamente."
