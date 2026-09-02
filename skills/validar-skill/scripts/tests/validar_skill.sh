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

# Algunos IDs ahora se auto-verifican (ver verificar_mecanico en el script):
# para 'skill-de-prueba' varios de esos van a ser DONE de verdad (el nombre
# coincide, la descripción y el cuerpo tienen longitud válida, no hay
# scripts/) y el script rechaza marcarlos NA. Probamos DONE primero; si el
# script lo rechaza (porque mecánicamente corresponde NA), caemos a NA.
while IFS= read -r id; do
  [ -n "$id" ] || continue
  if ! "$SCRIPT" mark skill-de-prueba "$id" DONE "marcado DONE para completar el test" >/dev/null 2>&1; then
    "$SCRIPT" mark skill-de-prueba "$id" NA "marcado NA para completar el test" >/dev/null
  fi
done < <(grep -oE '^\| `[a-z0-9-]+`' "$CHECKLIST_SRC" | sed -E 's/^\| `([a-z0-9-]+)`$/\1/')

out="$("$SCRIPT" status skill-de-prueba 2>&1)"; code=$?
assert_exit "status final sale con exit 0" 0 "$code"
assert_contains "status final informa COMPLETO" "$out" "VEREDICTO: COMPLETO"

# --- Verificación mecánica: no se puede marcar DONE lo que no lo está ---

mkdir -p skills/skill-test-roto/scripts/tests
cat > skills/skill-test-roto/SKILL.md <<'EOF'
---
name: skill-test-roto
description: Skill de prueba cuyo test bundleado falla de verdad.
---

# Skill test roto
EOF
cat > skills/skill-test-roto/scripts/algo.sh <<'EOF'
#!/usr/bin/env bash
echo "hago algo"
EOF
chmod +x skills/skill-test-roto/scripts/algo.sh
cat > skills/skill-test-roto/scripts/tests/algo.sh <<'EOF'
#!/usr/bin/env bash
echo "este test siempre falla" >&2
exit 1
EOF
chmod +x skills/skill-test-roto/scripts/tests/algo.sh

"$SCRIPT" init skill-test-roto >/dev/null 2>&1
out="$("$SCRIPT" mark skill-test-roto scripts-con-test DONE "el agente dice que pasa" 2>&1)"; code=$?
assert_exit "mark DONE de un test que falla de verdad es rechazado" 1 "$code"
assert_contains "el rechazo explica que el test falla al correrlo" "$out" "fallan al correrlos ahora"

out="$("$SCRIPT" mark skill-test-roto scripts-con-test NA "no aplica" 2>&1)"; code=$?
assert_exit "mark NA cuando en realidad scripts/ existe también es rechazado" 1 "$code"

# --- Verificación mecánica: el caso feliz (test que sí pasa) se acepta ---

mkdir -p skills/skill-test-ok/scripts/tests
cat > skills/skill-test-ok/SKILL.md <<'EOF'
---
name: skill-test-ok
description: Skill de prueba cuyo test bundleado pasa de verdad.
---

# Skill test ok
EOF
cat > skills/skill-test-ok/scripts/algo.sh <<'EOF'
#!/usr/bin/env bash
echo "hago algo"
EOF
chmod +x skills/skill-test-ok/scripts/algo.sh
cat > skills/skill-test-ok/scripts/tests/algo.sh <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x skills/skill-test-ok/scripts/tests/algo.sh

"$SCRIPT" init skill-test-ok >/dev/null 2>&1
out="$("$SCRIPT" mark skill-test-ok scripts-con-test DONE "nota" 2>&1)"; code=$?
assert_exit "mark DONE de un test que sí pasa se acepta" 0 "$code"

# --- Verificación mecánica: nombre de directorio vs 'name' del frontmatter ---

mkdir -p skills/skill-nombre-raro
cat > skills/skill-nombre-raro/SKILL.md <<'EOF'
---
name: otro-nombre
description: El directorio y el 'name' del frontmatter no coinciden a propósito.
---

# Nombre raro
EOF
"$SCRIPT" init skill-nombre-raro >/dev/null 2>&1
out="$("$SCRIPT" mark skill-nombre-raro dir-nombre-coincide DONE "el agente dice que coincide" 2>&1)"; code=$?
assert_exit "mark DONE cuando el nombre no coincide de verdad es rechazado" 1 "$code"
assert_contains "el rechazo explica el desajuste" "$out" "no coincide"

# --- Verificación mecánica: campo condicional presente no puede ser NA ---

mkdir -p skills/skill-con-license
cat > skills/skill-con-license/SKILL.md <<'EOF'
---
name: skill-con-license
description: Skill de prueba con el campo license presente en el frontmatter.
license: MIT
---

# Con license
EOF
"$SCRIPT" init skill-con-license >/dev/null 2>&1
out="$("$SCRIPT" mark skill-con-license license-formato NA "no aplica" 2>&1)"; code=$?
assert_exit "mark NA de license-formato cuando license existe es rechazado" 1 "$code"
assert_contains "el rechazo explica que el campo existe" "$out" "define 'license'"

out="$("$SCRIPT" mark skill-con-license license-formato DONE "MIT, nombre corto válido" 2>&1)"; code=$?
assert_exit "mark DONE de license-formato cuando license existe se acepta" 0 "$code"

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
