#!/usr/bin/env bash
# Test de plan_file.sh: valida el ciclo de vida de un archivo de plan
# exportado (validate/next/start/complete/block) contra un fixture temporal.
# Uso: scripts/tests/plan_file.sh (sin argumentos)
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/plan_file.sh"
TAB=$'\t'

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
plan="$workdir/plan.txt"

{
  printf 'META%sschema_version%s1\n' "$TAB" "$TAB"
  printf 'META%skind%simplementation-plan\n' "$TAB" "$TAB"
  printf 'META%sticket%sTEST-1\n' "$TAB" "$TAB"
  printf 'META%sstatus%sREADY\n' "$TAB" "$TAB"
  printf 'META%sexecution_status%sIN_PROGRESS\n' "$TAB" "$TAB"
  printf 'TASK%sT1%s1%sN1%sTarea 1%sDescripción 1%sPENDING%s%s%s%s%s\n' \
    "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'TASK%sT2%s2%sN2%sTarea 2%sDescripción 2%sPENDING%s%s%s%s%s\n' \
    "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB"
  printf 'DEP%sT2%sT1\n' "$TAB" "$TAB"
} > "$plan"

out="$("$SCRIPT" validate "$plan" 2>&1)"; code=$?
assert_exit "validate sobre plan válido sale con exit 0" 0 "$code"
assert_contains "validate informa task_count=2" "$out" "task_count=2"

out="$("$SCRIPT" next "$plan" 2>&1)"; code=$?
assert_exit "next inicial sale con exit 0" 0 "$code"
assert_contains "next inicial elige T1 (sin dependencias)" "$out" "task_id=T1"

out="$("$SCRIPT" start "$plan" --task-id T2 2>&1)"; code=$?
assert_exit "start de T2 antes que T1 falla" 1 "$code"
assert_contains "start de T2 informa dependencias no DONE" "$out" "dependencias"

out="$("$SCRIPT" start "$plan" --task-id T1 2>&1)"; code=$?
assert_exit "start de T1 sale con exit 0" 0 "$code"

out="$("$SCRIPT" next "$plan" 2>&1)"; code=$?
assert_contains "next tras start T1 espera dependencia" "$out" "action=WAIT_DEPENDENCY"

out="$("$SCRIPT" complete "$plan" --task-id T1 2>&1)"; code=$?
assert_exit "complete de T1 sin evidencia falla" 1 "$code"
assert_contains "complete sin evidencia informa el error" "$out" "evidencia"

out="$("$SCRIPT" complete "$plan" --task-id T1 --evidence "tests OK" 2>&1)"; code=$?
assert_exit "complete de T1 con evidencia sale con exit 0" 0 "$code"

out="$("$SCRIPT" next "$plan" 2>&1)"; code=$?
assert_contains "next tras completar T1 habilita T2" "$out" "task_id=T2"

out="$("$SCRIPT" start "$plan" --task-id T2 2>&1)"; code=$?
assert_exit "start de T2 tras T1 DONE sale con exit 0" 0 "$code"

out="$("$SCRIPT" complete "$plan" --task-id T2 --evidence "tests OK" 2>&1)"; code=$?
assert_exit "complete de T2 sale con exit 0" 0 "$code"
assert_contains "complete de T2 marca execution_status COMPLETE" "$out" "execution_status=COMPLETE"

out="$("$SCRIPT" next "$plan" 2>&1)"; code=$?
assert_contains "next final informa PLAN_COMPLETE" "$out" "action=PLAN_COMPLETE"

out="$("$SCRIPT" block "$plan" --task-id T1 --reason "no debería poder" 2>&1)"; code=$?
assert_exit "block sobre tarea DONE falla" 1 "$code"

out="$("$SCRIPT" complete "$plan" --task-id NOEXISTE --evidence "x" 2>&1)"; code=$?
assert_exit "complete sobre tarea inexistente falla" 1 "$code"
assert_contains "complete sobre tarea inexistente informa el error" "$out" "No existe la tarea"

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
