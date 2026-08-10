#!/usr/bin/env bash
# Test de validar_skill.sh: corre init/mark/pending/status contra un repo
# temporal aislado (no toca el repo real ni el TMPDIR real).
# Uso: scripts/tests/validar_skill.sh (sin argumentos)
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/validar_skill.sh"
CHECKLIST_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/validaciones.md"

pass=0
fail=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS  $desc"; pass=$((pass + 1))
  else
    echo "FAIL  $desc (esperado exit $expected, fue $actual)"; fail=$((fail + 1))
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF "$needle"; then
    echo "PASS  $desc"; pass=$((pass + 1))
  else
    echo "FAIL  $desc (no contiene: $needle)"; fail=$((fail + 1))
  fi
}

workdir="$(mktemp -d)"
export TMPDIR="$workdir/tmp"
mkdir -p "$TMPDIR" "$workdir/repo/skills/skill-de-prueba"
cd "$workdir/repo" || exit 1

cat > skills/skill-de-prueba/SKILL.md <<'EOF'
---
name: skill-de-prueba
description: Skill de prueba para testear validar_skill.sh.
---

# Skill de prueba

Contenido mínimo.
EOF

first_id="$(grep -oE '^\| `[a-z0-9-]+`' "$CHECKLIST_SRC" | head -1 | sed -E 's/^\| `([a-z0-9-]+)`$/\1/')"

out="$("$SCRIPT" init skill-de-prueba 2>&1)"; code=$?
assert_exit "init primera vez sale con exit 0" 0 "$code"
assert_contains "init primera vez informa 'primer init'" "$out" "primer init"
assert_contains "init primera vez arranca INCOMPLETO" "$out" "VEREDICTO: INCOMPLETO"

out="$("$SCRIPT" init skill-de-prueba 2>&1)"; code=$?
assert_exit "segundo init sin cambios sale con exit 0" 0 "$code"
assert_contains "segundo init informa 'sin cambios'" "$out" "sin cambios"

out="$("$SCRIPT" mark skill-de-prueba id-que-no-existe DONE "nota" 2>&1)"; code=$?
assert_exit "mark con id desconocido falla" 1 "$code"
assert_contains "mark con id desconocido informa el error" "$out" "ID desconocido"

out="$("$SCRIPT" mark skill-de-prueba "$first_id" MAYBE "nota" 2>&1)"; code=$?
assert_exit "mark con estado inválido falla" 1 "$code"
assert_contains "mark con estado inválido informa el error" "$out" "Estado inválido"

out="$("$SCRIPT" mark skill-de-prueba "$first_id" DONE "justificación de prueba" 2>&1)"; code=$?
assert_exit "mark válido sale con exit 0" 0 "$code"
assert_contains "mark válido confirma el id y estado" "$out" "$first_id=DONE"

out="$("$SCRIPT" pending skill-de-prueba 2>&1)"
if printf '%s\n' "$out" | grep -qx "$first_id"; then
  echo "FAIL  pending ya no debería listar $first_id"; fail=$((fail + 1))
else
  echo "PASS  pending ya no lista $first_id"; pass=$((pass + 1))
fi

mkdir -p skills/skill-sin-init
cat > skills/skill-sin-init/SKILL.md <<'EOF'
---
name: skill-sin-init
description: Otra skill de prueba, nunca inicializada.
---

# Skill sin init
EOF
out="$("$SCRIPT" mark skill-sin-init "$first_id" DONE "nota" 2>&1)"; code=$?
assert_exit "mark sin init previo falla" 1 "$code"
assert_contains "mark sin init previo informa el error" "$out" "No hay estado"

echo "Línea nueva que cambia el hash." >> skills/skill-de-prueba/SKILL.md
out="$("$SCRIPT" init skill-de-prueba 2>&1)"; code=$?
assert_exit "re-init tras cambio sale con exit 0" 0 "$code"
assert_contains "re-init tras cambio informa el reinicio" "$out" "el contenido cambió"
assert_contains "re-init tras cambio vuelve a INCOMPLETO" "$out" "VEREDICTO: INCOMPLETO"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  "$SCRIPT" mark skill-de-prueba "$id" NA "marcado NA para completar el test" >/dev/null
done < <(grep -oE '^\| `[a-z0-9-]+`' "$CHECKLIST_SRC" | sed -E 's/^\| `([a-z0-9-]+)`$/\1/')

out="$("$SCRIPT" status skill-de-prueba 2>&1)"; code=$?
assert_exit "status final sale con exit 0" 0 "$code"
assert_contains "status final informa COMPLETO" "$out" "VEREDICTO: COMPLETO"

cd / || true
rm -rf "$workdir"

echo "---"
echo "PASS=$pass FAIL=$fail"
if [ "$fail" -eq 0 ]; then
  echo "VEREDICTO: OK"
  exit 0
else
  echo "VEREDICTO: FALLÓ ($fail)"
  exit 1
fi
