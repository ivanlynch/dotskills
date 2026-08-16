#!/usr/bin/env bash
# Test de plan_state.sh: construye un scope CONFIRMED real con
# workflow_state.sh y ejercita el ciclo completo de planificación sobre ese
# mismo estado, incluyendo el export-file que consume plan_file.sh.
# Uso: scripts/tests/plan_state.sh (sin argumentos)
set -uo pipefail

PLAN_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/plan_state.sh"
PLAN_FILE_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/plan_file.sh"
WORKFLOW_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/workflow_state.sh"

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

out="$("$PLAN_SCRIPT" init NOSCOPE-1 2>&1)"; code=$?
assert_exit "init sin scope_analysis previo falla" 1 "$code"
assert_contains "init sin scope_analysis informa el error" "$out" "No hay análisis de alcance"

# --- construir un scope CONFIRMED real vía workflow_state.sh ---
"$WORKFLOW_SCRIPT" init TEST-1 >/dev/null
"$WORKFLOW_SCRIPT" start TEST-1 ticket >/dev/null
"$WORKFLOW_SCRIPT" context TEST-1 --id TEST-1 --title "Título" --description "Descripción" --source user >/dev/null
"$WORKFLOW_SCRIPT" done TEST-1 ticket --evidence "listo" >/dev/null
"$WORKFLOW_SCRIPT" start TEST-1 analizar-alcance >/dev/null
"$WORKFLOW_SCRIPT" scope-set-objective TEST-1 "Objetivo de prueba" >/dev/null
"$WORKFLOW_SCRIPT" scope-add-item TEST-1 TEST-1 - DONE APTO_PARA_IMPLEMENTAR "Item raíz" >/dev/null
"$WORKFLOW_SCRIPT" scope-set-criteria TEST-1 TEST-1 "El item cumple X" >/dev/null
"$WORKFLOW_SCRIPT" scope-confirm TEST-1 >/dev/null
"$WORKFLOW_SCRIPT" done TEST-1 analizar-alcance --evidence "scope confirmado" >/dev/null

out="$("$PLAN_SCRIPT" init TEST-1 2>&1)"; code=$?
assert_exit "init con scope CONFIRMED sale con exit 0" 0 "$code"
assert_contains "init informa dónde quedó el plan" "$out" "plan inicializado"

out="$("$PLAN_SCRIPT" validate TEST-1 2>&1)"; code=$?
assert_exit "validate tras init sale con exit 0" 0 "$code"

out="$("$PLAN_SCRIPT" next TEST-1 2>&1)"; code=$?
assert_contains "next inicial pide crear ticket para el work item" "$out" "action=CREATE_TICKET work_item=TEST-1"

out="$("$PLAN_SCRIPT" task-add TEST-1 --source-node-id TEST-1 --title "Tarea" --description "Descripción" --implementation-step "paso 1" --verification "verificación 1" 2>&1)"; code=$?
assert_exit "task-add sale con exit 0" 0 "$code"
assert_contains "task-add informa el id de la tarea" "$out" "task-add task-001"

out="$("$PLAN_SCRIPT" next TEST-1 2>&1)"; code=$?
assert_contains "next tras task-add pide revisar el work item" "$out" "action=REVIEW_WORK_ITEM work_item=TEST-1"

out="$("$PLAN_SCRIPT" item-complete TEST-1 --source-node-id TEST-1 2>&1)"; code=$?
assert_exit "item-complete sale con exit 0" 0 "$code"

out="$("$PLAN_SCRIPT" next TEST-1 2>&1)"; code=$?
assert_contains "next con todo planeado pide finalizar el plan" "$out" "action=FINALIZE_PLAN"

out="$("$PLAN_SCRIPT" complete TEST-1 --evidence "" 2>&1)"; code=$?
assert_exit "complete sin evidencia falla" 1 "$code"

out="$("$PLAN_SCRIPT" complete TEST-1 --evidence "plan listo" 2>&1)"; code=$?
assert_exit "complete con evidencia sale con exit 0" 0 "$code"
assert_contains "complete informa status COMPLETE" "$out" "status=COMPLETE"

out="$("$PLAN_SCRIPT" task-add TEST-1 --source-node-id TEST-1 --title "Otra" --description "Otra" --implementation-step "paso" --verification "verif" 2>&1)"; code=$?
assert_exit "task-add tras el plan COMPLETE falla" 1 "$code"
assert_contains "task-add tras COMPLETE informa el error" "$out" "IN_PROGRESS"

out="$("$PLAN_SCRIPT" export TEST-1 2>&1)"; code=$?
assert_exit "export sale con exit 0" 0 "$code"
assert_contains "export incluye el objetivo" "$out" "Objetivo de prueba"

output_file="$workdir/plan-exportado.txt"
out="$("$PLAN_SCRIPT" export-file TEST-1 --output "$output_file" 2>&1)"; code=$?
assert_exit "export-file sale con exit 0" 0 "$code"
assert_contains "export-file informa task_count=1" "$out" "task_count=1"

if [ -f "$output_file" ]; then
  echo "PASS  export-file escribió el archivo"; pass=$((pass + 1))
else
  echo "FAIL  export-file no escribió el archivo"; fail=$((fail + 1))
fi

out="$("$PLAN_FILE_SCRIPT" validate "$output_file" 2>&1)"; code=$?
assert_exit "plan_file.sh valida el archivo exportado" 0 "$code"
assert_contains "plan_file.sh confirma task_count=1 sobre el export" "$out" "task_count=1"

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
