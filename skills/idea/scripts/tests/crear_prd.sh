#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/../crear_prd.sh"

echo "Ejecutando tests para crear_prd.sh..."

if "$TARGET_SCRIPT" > /dev/null 2>&1; then
  echo "TEST FAIL: Debería fallar sin subcomando." >&2
  exit 1
else
  echo "PASS: Falla correctamente sin subcomando."
fi

if "$TARGET_SCRIPT" init > /dev/null 2>&1; then
  echo "TEST FAIL: 'init' debería fallar sin título." >&2
  exit 1
else
  echo "PASS: 'init' falla correctamente sin título."
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_OUTPUT="${TMP_DIR}/test-prd.md"
"$TARGET_SCRIPT" init "Sistema de Favoritos" "$TEST_OUTPUT" > /dev/null

if [ ! -f "$TEST_OUTPUT" ]; then
  echo "TEST FAIL: El archivo no fue creado." >&2
  exit 1
fi

if ! grep -q "Sistema de Favoritos" "$TEST_OUTPUT"; then
  echo "TEST FAIL: El título no fue reemplazado correctamente." >&2
  exit 1
fi
echo "PASS: 'init' crea el archivo y reemplaza el título."

(
  cd "$TMP_DIR"
  "$TARGET_SCRIPT" init "Otro Feature Sin Ruta" > /dev/null
  if [ ! -f "changes/otro-feature-sin-ruta/prd.md" ]; then
    echo "TEST FAIL: sin ruta_de_salida, 'init' debería guardar en changes/<slug>/prd.md." >&2
    exit 1
  fi
)
echo "PASS: 'init' sin ruta_de_salida usa por defecto changes/<slug>/prd.md."

TMP_ACENTOS="${TMP_DIR}/test-acentos.md"
"$TARGET_SCRIPT" init "Automatización de implementación post-PRD" "$TMP_ACENTOS" > /dev/null
if [ ! -f "$TMP_ACENTOS" ]; then
  echo "TEST FAIL: 'init' con título acentuado no creó el archivo en la ruta indicada." >&2
  exit 1
fi

(
  cd "$TMP_DIR"
  "$TARGET_SCRIPT" init "Automatización de implementación post-PRD" > /dev/null
  if [ ! -f "changes/automatizacion-de-implementacion-post-prd/prd.md" ]; then
    echo "TEST FAIL: el slug con acentos no se transliteró correctamente (á/é/í/ó/ú/ñ/ü)." >&2
    exit 1
  fi
)
echo "PASS: el slug transliteral vocales acentuadas y ñ en vez de cortarlas con guiones."

if "$TARGET_SCRIPT" check "$TEST_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería fallar mientras queden placeholders." >&2
  exit 1
else
  echo "PASS: 'check' detecta placeholders pendientes."
fi

"$TARGET_SCRIPT" add "$TEST_OUTPUT" --problema "Los usuarios pierden productos que quieren comprar después." > /dev/null
"$TARGET_SCRIPT" add "$TEST_OUTPUT" --objetivo "Permitir guardar productos para verlos más tarde." > /dev/null
"$TARGET_SCRIPT" add "$TEST_OUTPUT" --paso "El usuario abre la ficha de un producto." > /dev/null
"$TARGET_SCRIPT" add "$TEST_OUTPUT" --paso "El usuario toca el botón de favorito." --cerrar-lista > /dev/null

if ! grep -q "^1\. El usuario abre la ficha de un producto\.$" "$TEST_OUTPUT"; then
  echo "TEST FAIL: El paso 1 del flujo principal no quedó numerado correctamente." >&2
  exit 1
fi
if ! grep -q "^2\. El usuario toca el botón de favorito\.$" "$TEST_OUTPUT"; then
  echo "TEST FAIL: El paso 2 del flujo principal no quedó numerado correctamente." >&2
  exit 1
fi
echo "PASS: 'add --paso' numera los pasos del flujo principal en orden."

if grep -q "{{FLUJO_PRINCIPAL}}" "$TEST_OUTPUT"; then
  echo "TEST FAIL: --cerrar-lista debería haber eliminado el marcador de flujo principal." >&2
  exit 1
fi
echo "PASS: 'add --paso --cerrar-lista' agrega el último ítem y cierra la lista en la misma llamada."

if "$TARGET_SCRIPT" add "$TEST_OUTPUT" --paso "un paso de más" > /dev/null 2>&1; then
  echo "TEST FAIL: No debería permitir agregar pasos a una lista ya cerrada." >&2
  exit 1
else
  echo "PASS: 'add --paso' rechaza agregar a una lista ya cerrada."
fi

"$TARGET_SCRIPT" add "$TEST_OUTPUT" --requerimiento "Marcar favorito" "Un usuario logueado puede marcar/desmarcar un favorito." > /dev/null
"$TARGET_SCRIPT" add "$TEST_OUTPUT" --requerimiento "Persistencia" "La lista de favoritos persiste entre sesiones." > /dev/null

if ! grep -q "^#### RF-001: Marcar favorito$" "$TEST_OUTPUT"; then
  echo "TEST FAIL: El requerimiento 1 no quedó con el ID RF-001 esperado." >&2
  exit 1
fi
if ! grep -q "^#### RF-002: Persistencia$" "$TEST_OUTPUT"; then
  echo "TEST FAIL: El requerimiento 2 no quedó con el ID RF-002 esperado." >&2
  exit 1
fi
echo "PASS: 'add --requerimiento' asigna IDs RF-00N incrementales sin pisar los anteriores."

if ! grep -q "{{REQUERIMIENTOS}}" "$TEST_OUTPUT" || ! grep -q "{{OUT_OF_SCOPE}}" "$TEST_OUTPUT"; then
  echo "TEST FAIL: Los marcadores de lista deberían seguir presentes tras agregar ítems sin --cerrar-lista." >&2
  exit 1
fi
echo "PASS: sin --cerrar-lista, los marcadores siguen abiertos para poder seguir agregando ítems."

if "$TARGET_SCRIPT" add "$TEST_OUTPUT" --requerimiento "Sin descripción" > /dev/null 2>&1; then
  echo "TEST FAIL: --requerimiento debería exigir también una descripción, no solo un título." >&2
  exit 1
else
  echo "PASS: --requerimiento rechaza un título sin descripción."
fi

if "$TARGET_SCRIPT" add "$TEST_OUTPUT" --problema "otro texto" > /dev/null 2>&1; then
  echo "TEST FAIL: No debería permitir reemplazar un campo ya completado." >&2
  exit 1
else
  echo "PASS: 'add' rechaza reemplazar un placeholder ya completado."
fi

if "$TARGET_SCRIPT" check "$TEST_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería fallar mientras las listas de requerimientos/exclusiones sigan abiertas." >&2
  exit 1
else
  echo "PASS: 'check' detecta que las listas de ítems siguen abiertas."
fi

TMP2="${TMP_DIR}/test-cierre-vacio.md"
"$TARGET_SCRIPT" init "Otra Feature" "$TMP2" > /dev/null
if "$TARGET_SCRIPT" add "$TMP2" --exclusion "único ítem" --cerrar-lista > /dev/null 2>&1; then
  :
else
  echo "TEST FAIL: --cerrar-lista debería aceptarse cuando la lista tiene al menos un ítem, aunque sea el primero." >&2
  exit 1
fi
echo "PASS: --cerrar-lista funciona con un único ítem agregado en la misma llamada."

TMP3="${TMP_DIR}/test-cierre-solo-vacio.md"
"$TARGET_SCRIPT" init "Otra Feature Mas" "$TMP3" > /dev/null
if "$TARGET_SCRIPT" add "$TMP3" --requerimiento --cerrar-lista > /dev/null 2>&1; then
  echo "TEST FAIL: --cerrar-lista solo (sin texto) no debería aceptarse si la lista está vacía." >&2
  exit 1
else
  echo "PASS: --cerrar-lista solo se rechaza si no hay ningún ítem cargado."
fi

if "$TARGET_SCRIPT" add "$TMP2" --problema "x" --cerrar-lista > /dev/null 2>&1; then
  echo "TEST FAIL: --cerrar-lista debería rechazarse en --problema (no es una lista)." >&2
  exit 1
else
  echo "PASS: --cerrar-lista se rechaza en campos que no son lista."
fi

"$TARGET_SCRIPT" add "$TEST_OUTPUT" --requerimiento --cerrar-lista > /dev/null

"$TARGET_SCRIPT" add "$TEST_OUTPUT" --exclusion "Compartir la lista de favoritos con otros usuarios." > /dev/null
"$TARGET_SCRIPT" add "$TEST_OUTPUT" --exclusion --cerrar-lista > /dev/null

if grep -q "{{REQUERIMIENTOS}}" "$TEST_OUTPUT" || grep -q "{{OUT_OF_SCOPE}}" "$TEST_OUTPUT"; then
  echo "TEST FAIL: --cerrar-lista debería haber eliminado los marcadores de requerimientos/exclusiones." >&2
  exit 1
fi
echo "PASS: --cerrar-lista solo (sin texto) cierra la lista usando los ítems ya cargados en llamadas previas."

if ! "$TARGET_SCRIPT" check "$TEST_OUTPUT" > /dev/null 2>&1; then
  echo "TEST FAIL: 'check' debería pasar una vez completados todos los campos y listas." >&2
  exit 1
fi
echo "PASS: 'check' confirma que no quedan placeholders pendientes."

if ! diff -q <(cat -s "$TEST_OUTPUT") "$TEST_OUTPUT" > /dev/null; then
  echo "TEST FAIL: El PRD final tiene líneas en blanco duplicadas (separador del template + separador propio del requerimiento)." >&2
  exit 1
fi
echo "PASS: no quedan líneas en blanco duplicadas en el PRD final."

echo "Todos los tests pasaron correctamente."
