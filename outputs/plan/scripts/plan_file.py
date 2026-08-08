#!/usr/bin/env python3
"""Operaciones atómicas y fail-closed sobre el archivo ejecutable del plan."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


STATUSES = ("PENDING", "IN_PROGRESS", "DONE", "BLOCKED")


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def output(command: str, plan_file: Path, **fields: object) -> None:
    print(json.dumps({"ok": True, "command": command, "plan_file": str(plan_file), **fields}, ensure_ascii=False, indent=2))


def load(path_value: str) -> tuple[Path, dict]:
    path = Path(path_value).expanduser().resolve()
    if not path.exists():
        raise RuntimeError(f"No existe el archivo de plan: {path}")
    try:
        plan = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise RuntimeError(f"El archivo de plan no contiene JSON válido: {error}") from error
    if not isinstance(plan, dict):
        raise RuntimeError("El archivo de plan debe contener un objeto JSON.")
    return path, plan


def validate(plan: dict) -> list[str]:
    errors: list[str] = []
    if plan.get("schema_version") != 1:
        errors.append("schema_version debe ser 1.")
    if plan.get("kind") != "implementation-plan":
        errors.append("kind debe ser implementation-plan.")
    if not str(plan.get("ticket") or "").strip():
        errors.append("ticket es obligatorio.")
    tasks = plan.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        errors.append("tasks debe ser una lista no vacía.")
        return errors
    ids: set[str] = set()
    valid_ids = set()
    active = 0
    for task in tasks:
        if not isinstance(task, dict):
            errors.append("Cada tarea debe ser un objeto.")
            continue
        task_id = task.get("id")
        if not isinstance(task_id, str) or not task_id.strip():
            errors.append("Cada tarea requiere id.")
            continue
        if task_id in ids:
            errors.append(f"Tarea duplicada: {task_id}.")
        ids.add(task_id)
        valid_ids.add(task_id)
        if task.get("status") not in STATUSES:
            errors.append(f"La tarea {task_id} tiene status inválido.")
        if not isinstance(task.get("order"), int) or task["order"] < 1:
            errors.append(f"La tarea {task_id} requiere un order positivo.")
        if not str(task.get("title") or "").strip() or not str(task.get("description") or "").strip():
            errors.append(f"La tarea {task_id} requiere título y descripción.")
        if not isinstance(task.get("dependencies", []), list):
            errors.append(f"La tarea {task_id} requiere dependencies como lista.")
        if task.get("status") == "IN_PROGRESS":
            active += 1
        if task.get("status") == "DONE" and not str(task.get("evidence") or "").strip():
            errors.append(f"La tarea {task_id} está DONE sin evidencia.")
        if task.get("status") == "BLOCKED" and not str(task.get("blocked_reason") or "").strip():
            errors.append(f"La tarea {task_id} está BLOCKED sin motivo.")
    for task in tasks:
        if not isinstance(task, dict):
            continue
        for dependency in task.get("dependencies", []):
            if dependency not in valid_ids:
                errors.append(f"La dependencia {dependency} no existe.")
            if dependency == task.get("id"):
                errors.append(f"La tarea {task.get('id')} no puede depender de sí misma.")
    if active > 1:
        errors.append("Solo puede existir una tarea IN_PROGRESS.")
    if plan.get("execution_status") == "COMPLETE" and any(task.get("status") != "DONE" for task in tasks):
        errors.append("execution_status COMPLETE requiere todas las tareas DONE.")
    return sorted(set(errors))


def require_valid(plan: dict) -> None:
    errors = validate(plan)
    if errors:
        raise RuntimeError("Archivo de plan inválido: " + " | ".join(errors))


def save(path: Path, plan: dict) -> None:
    plan["updated_at"] = now()
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def find_task(plan: dict, task_id: str) -> dict:
    for task in plan["tasks"]:
        if task.get("id") == task_id:
            return task
    raise RuntimeError(f"No existe la tarea {task_id}.")


def dependencies_done(plan: dict, task: dict) -> bool:
    tasks = {item["id"]: item for item in plan["tasks"]}
    return all(tasks[dependency]["status"] == "DONE" for dependency in task.get("dependencies", []))


def cmd_validate(path_value: str) -> int:
    path, plan = load(path_value)
    require_valid(plan)
    output("validate", path, execution_status=plan.get("execution_status"), task_count=len(plan["tasks"]))
    return 0


def cmd_next(path_value: str) -> int:
    path, plan = load(path_value)
    require_valid(plan)
    if all(task["status"] == "DONE" for task in plan["tasks"]):
        output("next", path, action="PLAN_COMPLETE", execution_status="COMPLETE")
        return 0
    blocked = [task["id"] for task in plan["tasks"] if task["status"] == "BLOCKED"]
    if blocked:
        output("next", path, action="BLOCKED", blocked_tasks=blocked)
        return 0
    for task in sorted(plan["tasks"], key=lambda item: item["order"]):
        if task["status"] == "PENDING" and dependencies_done(plan, task):
            output("next", path, action="IMPLEMENT_TASK", task=task)
            return 0
    output("next", path, action="WAIT_DEPENDENCY")
    return 0


def cmd_start(path_value: str, task_id: str) -> int:
    path, plan = load(path_value)
    require_valid(plan)
    task = find_task(plan, task_id)
    if task["status"] != "PENDING":
        raise RuntimeError(f"La tarea {task_id} debe estar PENDING para iniciar.")
    if not dependencies_done(plan, task):
        raise RuntimeError(f"Las dependencias de {task_id} no están DONE.")
    task["status"] = "IN_PROGRESS"
    task["started_at"] = now()
    save(path, plan)
    require_valid(plan)
    output("start", path, action="IMPLEMENT_TASK", task=task)
    return 0


def cmd_complete(path_value: str, task_id: str, evidence: str) -> int:
    path, plan = load(path_value)
    require_valid(plan)
    task = find_task(plan, task_id)
    if task["status"] != "IN_PROGRESS":
        raise RuntimeError(f"La tarea {task_id} debe estar IN_PROGRESS para completarse.")
    if not evidence.strip():
        raise RuntimeError("Se requiere evidencia no vacía.")
    task["status"] = "DONE"
    task["evidence"] = evidence.strip()
    task["completed_at"] = now()
    if all(item["status"] == "DONE" for item in plan["tasks"]):
        plan["execution_status"] = "COMPLETE"
    save(path, plan)
    require_valid(plan)
    output("complete", path, action="DONE", task=task, execution_status=plan["execution_status"])
    return 0


def cmd_block(path_value: str, task_id: str, reason: str) -> int:
    path, plan = load(path_value)
    require_valid(plan)
    task = find_task(plan, task_id)
    if task["status"] not in ("PENDING", "IN_PROGRESS"):
        raise RuntimeError(f"La tarea {task_id} no puede bloquearse desde {task['status']}.")
    if not reason.strip():
        raise RuntimeError("Se requiere un motivo no vacío.")
    task["status"] = "BLOCKED"
    task["blocked_reason"] = reason.strip()
    save(path, plan)
    require_valid(plan)
    output("block", path, action="RESOLVE_BLOCKER", task_id=task_id)
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="Estado del archivo ejecutable del plan.")
    commands = root.add_subparsers(dest="command", required=True)
    for name in ("validate", "next"):
        command = commands.add_parser(name)
        command.add_argument("plan_file")
    start = commands.add_parser("start")
    start.add_argument("plan_file")
    start.add_argument("--task-id", required=True)
    complete = commands.add_parser("complete")
    complete.add_argument("plan_file")
    complete.add_argument("--task-id", required=True)
    complete.add_argument("--evidence", required=True)
    block = commands.add_parser("block")
    block.add_argument("plan_file")
    block.add_argument("--task-id", required=True)
    block.add_argument("--reason", required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "validate":
            return cmd_validate(args.plan_file)
        if args.command == "next":
            return cmd_next(args.plan_file)
        if args.command == "start":
            return cmd_start(args.plan_file, args.task_id)
        if args.command == "complete":
            return cmd_complete(args.plan_file, args.task_id, args.evidence)
        if args.command == "block":
            return cmd_block(args.plan_file, args.task_id, args.reason)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(json.dumps({"ok": False, "command": args.command, "error": {"message": str(error)}}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
