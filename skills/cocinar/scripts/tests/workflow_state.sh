#!/usr/bin/env bash
# Test de workflow_state.sh: recorre el flujo completo (ticket_context,
# scope_analysis, fases, next-id, veredicto) contra un TMPDIR aislado.
# Uso: scripts/tests/workflow_state.sh (sin argumentos)
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflow_state.sh"

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
mkdir -p "$TMPDIR" "$workdir/repo"
cd "$workdir/repo" || exit 1

out="$("$SCRIPT" init TICKET-1 2>&1)"; code=$?
assert_exit "init sale con exit 0" 0 "$code"
assert_contains "init crea el registro" "$out" "registro creado"

out="$("$SCRIPT" init TICKET-1 2>&1)"; code=$?
assert_exit "segundo init sobre el mismo ticket sale con exit 0" 0 "$code"
assert_contains "segundo init informa registro existente" "$out" "registro existente"

out="$("$SCRIPT" context TICKET-1 --id TICKET-1 --title "T" --description "D" --source user 2>&1)"; code=$?
assert_exit "context antes de start ticket falla" 1 "$code"
assert_contains "context antes de start informa el error" "$out" "IN_PROGRESS"

out="$("$SCRIPT" start TICKET-1 ticket 2>&1)"; code=$?
assert_exit "start de la fase ticket sale con exit 0" 0 "$code"

out="$("$SCRIPT" context TICKET-1 --id TICKET-1 --title "Título de prueba" --description "Descripción de prueba" --source user 2>&1)"; code=$?
assert_exit "context válido sale con exit 0" 0 "$code"
assert_contains "context válido informa COMPLETE" "$out" "ticket_context=COMPLETE"

out="$("$SCRIPT" done TICKET-1 ticket --evidence "listo" 2>&1)"; code=$?
assert_exit "done de la fase ticket sale con exit 0" 0 "$code"

out="$("$SCRIPT" start TICKET-1 entrevistar 2>&1)"; code=$?
assert_exit "start de entrevistar antes del scope confirmado falla" 1 "$code"
assert_contains "start de entrevistar informa scope no confirmado" "$out" "scope_analysis"

out="$("$SCRIPT" start TICKET-1 analizar-alcance 2>&1)"; code=$?
assert_exit "start de analizar-alcance sale con exit 0" 0 "$code"

out="$("$SCRIPT" scope-set-objective TICKET-1 "Objetivo de prueba" 2>&1)"; code=$?
assert_exit "scope-set-objective sale con exit 0" 0 "$code"

out="$("$SCRIPT" scope-add-item TICKET-1 TICKET-1 - DONE APTO_PARA_IMPLEMENTAR "Item raíz" 2>&1)"; code=$?
assert_exit "scope-add-item del nodo raíz sale con exit 0" 0 "$code"

out="$("$SCRIPT" scope-confirm TICKET-1 2>&1)"; code=$?
assert_exit "scope-confirm sin criterios falla" 1 "$code"
assert_contains "scope-confirm sin criterios informa el error" "$out" "acceptance_criteria"

out="$("$SCRIPT" scope-set-criteria TICKET-1 TICKET-1 "El item cumple X" 2>&1)"; code=$?
assert_exit "scope-set-criteria sale con exit 0" 0 "$code"

out="$("$SCRIPT" scope-confirm TICKET-1 2>&1)"; code=$?
assert_exit "scope-confirm con criterios sale con exit 0" 0 "$code"
assert_contains "scope-confirm informa CONFIRMED" "$out" "scope_analysis=CONFIRMED"

out="$("$SCRIPT" validate TICKET-1 2>&1)"; code=$?
assert_exit "validate tras confirmar sale con exit 0" 0 "$code"
assert_contains "validate informa VALID" "$out" "VALID"

out="$("$SCRIPT" done TICKET-1 analizar-alcance --evidence "scope confirmado" 2>&1)"; code=$?
assert_exit "done de analizar-alcance sale con exit 0" 0 "$code"

out="$("$SCRIPT" block TICKET-1 ticket --reason "no debería poder" 2>&1)"; code=$?
assert_exit "block sobre fase ya DONE falla" 1 "$code"

out="$("$SCRIPT" block TICKET-1 entrevistar --reason "esperando al cliente" 2>&1)"; code=$?
assert_exit "block de una fase pendiente sale con exit 0" 0 "$code"
assert_contains "block informa BLOCKED" "$out" "entrevistar=BLOCKED"

id1="$("$SCRIPT" next-id)"
id2="$("$SCRIPT" next-id)"
assert_contains "next-id primer valor tiene el prefijo TASK-" "$id1" "TASK-"
if [ "$id1" != "$id2" ]; then
  echo "PASS  next-id devuelve valores distintos en llamadas sucesivas"; pass=$((pass + 1))
else
  echo "FAIL  next-id repitió el mismo valor: $id1"; fail=$((fail + 1))
fi

out="$("$SCRIPT" check-verdict TICKET-1 2>&1)"; code=$?
assert_exit "check-verdict sin archivo de veredicto falla" 1 "$code"
assert_contains "check-verdict informa el error" "$out" "No existe el veredicto"

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
