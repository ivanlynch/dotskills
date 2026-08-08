#!/usr/bin/env python3
"""Estado fail-closed y operaciones pequeñas para la skill $plan."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


TICKET_RE = re.compile(r"^[A-Z][A-Z0-9]+-[0-9]+$")
PLAN_STATUSES = ("IN_PROGRESS", "COMPLETE", "BLOCKED")
TASK_STATUSES = ("READY", "BLOCKED")


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_ticket(raw: str) -> str:
    ticket = raw.strip().upper()
    if not TICKET_RE.fullmatch(ticket):
        raise ValueError(f"ID de Jira inválido: {raw!r}.")
    return ticket


def state_path(ticket: str) -> Path:
    project = str(Path.cwd().resolve())
    digest = hashlib.sha256(project.encode()).hexdigest()[:12]
    return Path(os.environ.get("TMPDIR", "/tmp")) / f"plan-{ticket.lower()}-{digest}-state.json"


def save(path: Path, state: dict) -> None:
    state["updated_at"] = now()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def load(ticket: str) -> tuple[Path, dict]:
    path = state_path(ticket)
    if not path.exists():
        raise RuntimeError(f"No existe estado de plan para {ticket}. Ejecuta init primero.")
    state = json.loads(path.read_text(encoding="utf-8"))
    if state.get("ticket") != ticket or state.get("project") != str(Path.cwd().resolve()):
        raise RuntimeError("El estado no corresponde al ticket o proyecto actual.")
    return path, state


def parse_json(raw: str, label: str) -> dict:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"{label} no contiene JSON válido: {error}") from error
    if not isinstance(value, dict):
        raise RuntimeError(f"{label} debe ser un objeto JSON.")
    return value


def read_scope(scope_json: str | None, scope_file: str | None) -> dict:
    if bool(scope_json) == bool(scope_file):
        raise RuntimeError("Indica exactamente uno de --scope-json o --scope-file.")
    if scope_file:
        try:
            scope_json = Path(scope_file).read_text(encoding="utf-8")
        except OSError as error:
            raise RuntimeError(f"No se pudo leer --scope-file: {error}") from error
    return parse_json(scope_json or "", "scope_handoff")


def validate_scope(scope: dict, ticket: str) -> list[str]:
    errors: list[str] = []
    if scope.get("action") != "ANALYSIS_COMPLETE":
        errors.append("scope_handoff.action debe ser ANALYSIS_COMPLETE.")
    if scope.get("next_phase") != "plan":
        errors.append("scope_handoff.next_phase debe ser plan.")
    if scope.get("ticket") not in (None, ticket):
        errors.append("scope_handoff.ticket no coincide con el ticket solicitado.")
    handoff = scope.get("scope_handoff")
    if not isinstance(handoff, dict):
        errors.append("scope_handoff debe ser un objeto.")
        return errors
    if not str(handoff.get("objective") or "").strip():
        errors.append("scope_handoff.objective es obligatorio.")
    work_items = handoff.get("work_items")
    if not isinstance(work_items, list) or not work_items:
        errors.append("scope_handoff.work_items debe ser una lista no vacía.")
    else:
        ids: set[str] = set()
        for item in work_items:
            if not isinstance(item, dict):
                errors.append("Cada work item debe ser un objeto.")
                continue
            item_id = item.get("id")
            if not isinstance(item_id, str) or not item_id.strip():
                errors.append("Cada work item requiere un id.")
            elif item_id in ids:
                errors.append(f"Work item duplicado: {item_id}.")
            else:
                ids.add(item_id)
            if not str(item.get("title") or "").strip():
                errors.append(f"El work item {item_id or '<sin id>'} requiere title.")
            if not isinstance(item.get("acceptance_criteria", []), list):
                errors.append(f"El work item {item_id or '<sin id>'} requiere acceptance_criteria como lista.")
    return errors


def validate_state(state: dict) -> list[str]:
    errors = validate_scope(state.get("scope_input", {}), state["ticket"])
    if state.get("status") not in PLAN_STATUSES:
        errors.append("status de plan inválido.")
    tasks = state.get("tasks")
    if not isinstance(tasks, dict):
        errors.append("tasks debe ser un objeto.")
        tasks = {}
    item_ids = {
        item["id"]
        for item in state.get("scope_input", {}).get("scope_handoff", {}).get("work_items", [])
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    for task_id, task in tasks.items():
        if not isinstance(task, dict):
            errors.append(f"La tarea {task_id} debe ser un objeto.")
            continue
        for field in ("id", "source_node_id", "title", "description", "status", "implementation_steps", "verifications"):
            if field not in task:
                errors.append(f"La tarea {task_id} requiere {field}.")
        if task.get("id") != task_id:
            errors.append(f"El id de la tarea {task_id} no coincide con su clave.")
        if task.get("source_node_id") not in item_ids:
            errors.append(f"La tarea {task_id} referencia un work item inexistente.")
        if task.get("status") not in TASK_STATUSES:
            errors.append(f"La tarea {task_id} tiene status inválido.")
        if not str(task.get("title") or "").strip() or not str(task.get("description") or "").strip():
            errors.append(f"La tarea {task_id} requiere título y descripción.")
        if not isinstance(task.get("implementation_steps"), list) or not task.get("implementation_steps"):
            errors.append(f"La tarea {task_id} requiere pasos de implementación.")
        if not isinstance(task.get("verifications"), list) or not task.get("verifications"):
            errors.append(f"La tarea {task_id} requiere verificaciones.")
        if task.get("status") == "BLOCKED" and not str(task.get("blocked_reason") or "").strip():
            errors.append(f"La tarea {task_id} está BLOCKED sin motivo.")
    planned = state.get("planned_work_items", [])
    if not isinstance(planned, list) or any(item_id not in item_ids for item_id in planned):
        errors.append("planned_work_items contiene referencias inválidas.")
    if state.get("status") == "COMPLETE":
        if set(planned) != item_ids:
            errors.append("El plan está COMPLETE pero hay work items sin cerrar.")
        if any(task.get("status") != "READY" for task in tasks.values()):
            errors.append("El plan está COMPLETE pero hay tareas no listas.")
    return sorted(set(errors))


def require_valid(state: dict) -> None:
    errors = validate_state(state)
    if errors:
        raise RuntimeError("Estado inválido: " + " | ".join(errors))


def output(command: str, ticket: str, **fields: object) -> None:
    payload = {"ok": True, "command": command, "ticket": ticket, **fields}
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def cmd_init(ticket: str, scope_json: str | None, scope_file: str | None) -> int:
    path = state_path(ticket)
    if path.exists():
        _, state = load(ticket)
        require_valid(state)
        output("init", ticket, status=state["status"], state=str(path), reused=True)
        return 0
    scope = read_scope(scope_json, scope_file)
    errors = validate_scope(scope, ticket)
    if errors:
        raise RuntimeError("scope_handoff inválido: " + " | ".join(errors))
    state = {
        "schema_version": 1,
        "ticket": ticket,
        "project": str(Path.cwd().resolve()),
        "created_at": now(),
        "updated_at": now(),
        "status": "IN_PROGRESS",
        "scope_input": scope,
        "tasks": {},
        "planned_work_items": [],
    }
    save(path, state)
    output("init", ticket, status=state["status"], state=str(path), reused=False)
    return 0


def cmd_validate(ticket: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    output("validate", ticket, status=state["status"], state=str(path))
    return 0


def work_items(state: dict) -> list[dict]:
    return state["scope_input"]["scope_handoff"]["work_items"]


def cmd_next(ticket: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    planned = set(state["planned_work_items"])
    task_by_item = {task["source_node_id"] for task in state["tasks"].values()}
    for item in work_items(state):
        if item["id"] not in planned:
            action = "CREATE_TICKET" if item["id"] not in task_by_item else "REVIEW_WORK_ITEM"
            output("next", ticket, action=action, next_phase="plan", state=str(path), work_item=item)
            return 0
    output("next", ticket, action="PLAN_COMPLETE" if state["status"] == "COMPLETE" else "FINALIZE_PLAN", next_phase="implementacion" if state["status"] == "COMPLETE" else "plan", state=str(path))
    return 0


def next_task_id(tasks: dict) -> str:
    return f"task-{len(tasks) + 1:03d}"


def cmd_task_add(ticket: str, source_node_id: str, title: str, description: str, steps: list[str], verifications: list[str], dependencies: list[str]) -> int:
    path, state = load(ticket)
    require_valid(state)
    if state["status"] != "IN_PROGRESS":
        raise RuntimeError("Solo se pueden agregar tareas mientras el plan está IN_PROGRESS.")
    item_ids = {item["id"] for item in work_items(state)}
    if source_node_id not in item_ids:
        raise RuntimeError(f"No existe el work item {source_node_id}.")
    for dependency in dependencies:
        if dependency not in state["tasks"]:
            raise RuntimeError(f"No existe la dependencia {dependency}.")
    task_id = next_task_id(state["tasks"])
    state["tasks"][task_id] = {
        "id": task_id,
        "source_node_id": source_node_id,
        "title": title.strip(),
        "description": description.strip(),
        "status": "READY",
        "dependencies": dependencies,
        "implementation_steps": [step.strip() for step in steps if step.strip()],
        "verifications": [verification.strip() for verification in verifications if verification.strip()],
        "created_at": now(),
        "updated_at": now(),
    }
    require_valid(state)
    save(path, state)
    output("task-add", ticket, task=state["tasks"][task_id], state=str(path))
    return 0


def cmd_item_complete(ticket: str, source_node_id: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    if source_node_id in state["planned_work_items"]:
        raise RuntimeError(f"El work item {source_node_id} ya está completo.")
    tasks = [task for task in state["tasks"].values() if task["source_node_id"] == source_node_id]
    if not tasks:
        raise RuntimeError("El work item requiere al menos una tarea persistida.")
    blocked = [task["id"] for task in tasks if task["status"] != "READY"]
    if blocked:
        raise RuntimeError(f"No se puede cerrar el work item; tareas no listas: {', '.join(blocked)}.")
    state["planned_work_items"].append(source_node_id)
    state["planned_work_items"].sort()
    require_valid(state)
    save(path, state)
    output("item-complete", ticket, source_node_id=source_node_id, state=str(path))
    return 0


def cmd_complete(ticket: str, evidence: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    if not evidence.strip():
        raise RuntimeError("Se requiere evidencia no vacía.")
    if set(state["planned_work_items"]) != {item["id"] for item in work_items(state)}:
        raise RuntimeError("No se puede completar el plan mientras haya work items pendientes.")
    if any(task["status"] != "READY" for task in state["tasks"].values()):
        raise RuntimeError("No se puede completar el plan con tareas bloqueadas.")
    state["status"] = "COMPLETE"
    state["completion_evidence"] = evidence.strip()
    require_valid(state)
    save(path, state)
    output("complete", ticket, status=state["status"], state=str(path))
    return 0


def cmd_export(ticket: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    if state["status"] != "COMPLETE":
        raise RuntimeError("Solo se puede exportar un plan COMPLETE.")
    handoff = state["scope_input"]["scope_handoff"]
    output(
        "export",
        ticket,
        action="PLAN_COMPLETE",
        next_phase="implementacion",
        plan_handoff={
            "objective": handoff["objective"],
            "included": handoff.get("included", []),
            "excluded": handoff.get("excluded", []),
            "tasks": list(state["tasks"].values()),
            "dependencies": handoff.get("dependencies", []),
            "risks": handoff.get("risks", []),
            "assumptions": handoff.get("assumptions", []),
            "constraints": handoff.get("constraints", []),
        },
        state=str(path),
    )
    return 0


def cmd_export_file(ticket: str, output_file: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    if state["status"] != "COMPLETE":
        raise RuntimeError("Solo se puede exportar un plan COMPLETE.")
    handoff = state["scope_input"]["scope_handoff"]
    tasks = []
    for order, task in enumerate(state["tasks"].values(), start=1):
        tasks.append(
            {
                "id": task["id"],
                "order": order,
                "source_node_id": task["source_node_id"],
                "title": task["title"],
                "description": task["description"],
                "implementation_steps": task["implementation_steps"],
                "verifications": task["verifications"],
                "dependencies": task["dependencies"],
                "status": "PENDING",
                "evidence": None,
                "started_at": None,
                "completed_at": None,
            }
        )
    plan_file = {
        "schema_version": 1,
        "kind": "implementation-plan",
        "ticket": ticket,
        "status": "READY",
        "execution_status": "PENDING",
        "generated_at": now(),
        "objective": handoff["objective"],
        "included": handoff.get("included", []),
        "excluded": handoff.get("excluded", []),
        "dependencies": handoff.get("dependencies", []),
        "risks": handoff.get("risks", []),
        "assumptions": handoff.get("assumptions", []),
        "constraints": handoff.get("constraints", []),
        "tasks": tasks,
    }
    destination = Path(output_file).expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_text(json.dumps(plan_file, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(destination)
    output("export-file", ticket, action="PLAN_FILE_CREATED", plan_file=str(destination), task_count=len(tasks))
    return 0


def cmd_block(ticket: str, task_id: str, reason: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    task = state["tasks"].get(task_id)
    if not task:
        raise RuntimeError(f"No existe la tarea {task_id}.")
    if not reason.strip():
        raise RuntimeError("Se requiere un motivo no vacío.")
    task["status"] = "BLOCKED"
    task["blocked_reason"] = reason.strip()
    task["updated_at"] = now()
    state["status"] = "BLOCKED"
    require_valid(state)
    save(path, state)
    output("task-block", ticket, task_id=task_id, action="RESOLVE_BLOCKER", state=str(path))
    return 0


def cmd_unblock(ticket: str, task_id: str, resolution: str) -> int:
    path, state = load(ticket)
    require_valid(state)
    task = state["tasks"].get(task_id)
    if not task:
        raise RuntimeError(f"No existe la tarea {task_id}.")
    if task.get("status") != "BLOCKED":
        raise RuntimeError(f"La tarea {task_id} no está BLOCKED.")
    if not resolution.strip():
        raise RuntimeError("Se requiere una resolución no vacía.")
    task["status"] = "READY"
    task["resolution"] = resolution.strip()
    task["blocked_reason"] = None
    task["updated_at"] = now()
    state["status"] = "IN_PROGRESS"
    require_valid(state)
    save(path, state)
    output("task-unblock", ticket, task_id=task_id, action="REANALYZE_TASK", state=str(path))
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="Estado validado del comando $plan.")
    commands = root.add_subparsers(dest="command", required=True)
    init = commands.add_parser("init")
    init.add_argument("ticket")
    init.add_argument("--scope-json")
    init.add_argument("--scope-file")
    for name in ("validate", "next", "export"):
        command = commands.add_parser(name)
        command.add_argument("ticket")
    export_file = commands.add_parser("export-file")
    export_file.add_argument("ticket")
    export_file.add_argument("--output", required=True)
    task_add = commands.add_parser("task-add")
    task_add.add_argument("ticket")
    task_add.add_argument("--source-node-id", required=True)
    task_add.add_argument("--title", required=True)
    task_add.add_argument("--description", required=True)
    task_add.add_argument("--implementation-step", action="append", required=True, dest="steps")
    task_add.add_argument("--verification", action="append", required=True, dest="verifications")
    task_add.add_argument("--depends-on", action="append", default=[], dest="dependencies")
    item_complete = commands.add_parser("item-complete")
    item_complete.add_argument("ticket")
    item_complete.add_argument("--source-node-id", required=True)
    complete = commands.add_parser("complete")
    complete.add_argument("ticket")
    complete.add_argument("--evidence", required=True)
    block = commands.add_parser("task-block")
    block.add_argument("ticket")
    block.add_argument("--task-id", required=True)
    block.add_argument("--reason", required=True)
    unblock = commands.add_parser("task-unblock")
    unblock.add_argument("ticket")
    unblock.add_argument("--task-id", required=True)
    unblock.add_argument("--resolution", required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        ticket = normalize_ticket(args.ticket)
        if args.command == "init":
            return cmd_init(ticket, args.scope_json, args.scope_file)
        if args.command == "validate":
            return cmd_validate(ticket)
        if args.command == "next":
            return cmd_next(ticket)
        if args.command == "task-add":
            return cmd_task_add(ticket, args.source_node_id, args.title, args.description, args.steps, args.verifications, args.dependencies)
        if args.command == "item-complete":
            return cmd_item_complete(ticket, args.source_node_id)
        if args.command == "complete":
            return cmd_complete(ticket, args.evidence)
        if args.command == "export":
            return cmd_export(ticket)
        if args.command == "export-file":
            return cmd_export_file(ticket, args.output)
        if args.command == "task-block":
            return cmd_block(ticket, args.task_id, args.reason)
        if args.command == "task-unblock":
            return cmd_unblock(ticket, args.task_id, args.resolution)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(json.dumps({"ok": False, "command": args.command, "error": {"message": str(error)}}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
