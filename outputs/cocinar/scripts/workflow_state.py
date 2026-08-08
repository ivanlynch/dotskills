#!/usr/bin/env python3
"""Registro secuencial y fail-closed para el flujo del skill cocinar."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


PHASES = (
    "ticket",
    "analizar-alcance",
    "entrevistar",
    "guia-proyecto",
    "plan",
    "aprobacion",
    "branch",
    "implementacion",
    "pr",
)
TICKET_RE = re.compile(r"^[A-Z][A-Z0-9]+-[0-9]+$")
SCOPE_STATUSES = ("PENDING", "IN_PROGRESS", "BLOCKED", "DONE")
SCOPE_VERDICTS = (
    "APTO_PARA_IMPLEMENTAR",
    "REQUIERE_DIVISION",
    "BLOQUEADO",
)


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_ticket(raw: str) -> str:
    ticket = raw.strip().upper()
    if not TICKET_RE.fullmatch(ticket):
        raise ValueError(
            f"ID de Jira inválido: {raw!r}. Formato esperado: DTCZE-1234"
        )
    return ticket


def state_path(ticket: str) -> Path:
    project = str(Path.cwd().resolve())
    project_hash = hashlib.sha256(project.encode()).hexdigest()[:12]
    temp_root = Path(os.environ.get("TMPDIR", "/tmp"))
    return temp_root / f"cocinar-{ticket.lower()}-{project_hash}-state.json"


def new_state(ticket: str) -> dict:
    return {
        "ticket": ticket,
        "project": str(Path.cwd().resolve()),
        "created_at": now(),
        "updated_at": now(),
        "ticket_context": {
            "complete": False,
            "id": {"value": ticket, "source": "argument", "confirmed": True},
            "title": {"value": None, "source": None, "confirmed": False},
            "description": {"value": None, "source": None, "confirmed": False},
        },
        "scope_analysis": {
            "version": 1,
            "status": "PENDING",
            "root": ticket,
            "items": {},
            "updated_at": None,
        },
        "phases": {
            phase: {
                "status": "PENDING",
                "evidence": None,
                "reason": None,
                "updated_at": None,
            }
            for phase in PHASES
        },
    }


def empty_phase() -> dict:
    return {
        "status": "PENDING",
        "evidence": None,
        "reason": None,
        "updated_at": None,
    }


def save(path: Path, state: dict) -> None:
    state["updated_at"] = now()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def load(ticket: str) -> tuple[Path, dict]:
    path = state_path(ticket)
    if not path.exists():
        raise RuntimeError(
            f"No existe registro para {ticket}. Ejecuta primero: "
            f"workflow_state.py init {ticket}"
        )
    state = json.loads(path.read_text(encoding="utf-8"))
    if state.get("ticket") != ticket:
        raise RuntimeError("El registro no corresponde al ticket solicitado.")
    if state.get("project") != str(Path.cwd().resolve()):
        raise RuntimeError("El registro pertenece a otro proyecto.")
    state.setdefault(
        "ticket_context",
        {
            "complete": False,
            "id": {"value": ticket, "source": "argument", "confirmed": True},
            "title": {"value": None, "source": None, "confirmed": False},
            "description": {"value": None, "source": None, "confirmed": False},
        },
    )
    state.setdefault(
        "scope_analysis",
        {"version": 1, "status": "PENDING", "root": ticket, "items": {}, "updated_at": None},
    )
    for phase in PHASES:
        state["phases"].setdefault(phase, empty_phase())
    return path, state


def context_complete(state: dict) -> bool:
    context = state.get("ticket_context", {})
    if context.get("complete") is not True:
        return False
    return all(
        context.get(field, {}).get("confirmed") is True
        and bool(str(context.get(field, {}).get("value") or "").strip())
        for field in ("id", "title", "description")
    )


def validate_scope(scope: dict, ticket: str) -> list[str]:
    errors: list[str] = []
    if not isinstance(scope, dict):
        return ["scope_analysis debe ser un objeto."]
    items = scope.get("items")
    if not isinstance(items, dict):
        return ["scope_analysis.items debe ser un objeto."]
    root = scope.get("root")
    if root != ticket:
        errors.append(f"scope_analysis.root debe ser {ticket}.")
    if items and root not in items:
        errors.append("scope_analysis.items debe contener el nodo raíz.")
    for item_id, item in items.items():
        if not isinstance(item, dict):
            errors.append(f"El nodo {item_id} debe ser un objeto.")
            continue
        for field in ("title", "status", "verdict", "parent", "children"):
            if field not in item:
                errors.append(f"El nodo {item_id} requiere el campo {field}.")
        if not str(item.get("title") or "").strip():
            errors.append(f"El nodo {item_id} requiere un título no vacío.")
        if item.get("status") not in SCOPE_STATUSES:
            errors.append(f"El nodo {item_id} tiene un status inválido.")
        if item.get("verdict") not in SCOPE_VERDICTS:
            errors.append(f"El nodo {item_id} tiene un verdict inválido.")
        children = item.get("children")
        if not isinstance(children, list) or any(not isinstance(child, str) for child in children):
            errors.append(f"El nodo {item_id} requiere children como lista de IDs.")
        if item.get("parent") is not None and item.get("parent") not in items:
            errors.append(f"El padre del nodo {item_id} no existe.")
        if item.get("status") == "DONE" and item.get("verdict") not in (
            "APTO_PARA_IMPLEMENTAR",
            "REQUIERE_DIVISION",
        ):
            errors.append(
                f"El nodo {item_id} solo puede estar DONE si es apto o si su división fue resuelta."
            )
        if item.get("verdict") == "REQUIERE_DIVISION" and not item.get("children"):
            errors.append(f"El nodo {item_id} requiere hijos si su veredicto es REQUIERE_DIVISION.")
        if item.get("status") == "BLOCKED" and item.get("verdict") != "BLOQUEADO":
            errors.append(f"El nodo {item_id} solo puede estar BLOCKED si está bloqueado.")
        if item.get("status") == "BLOCKED" and item.get("children"):
            errors.append(f"El nodo {item_id} no puede tener hijos mientras está BLOCKED.")
    for item_id, item in items.items():
        for child_id in item.get("children", []) if isinstance(item, dict) else []:
            if child_id not in items:
                errors.append(f"El hijo {child_id} del nodo {item_id} no existe.")
            elif items[child_id].get("parent") != item_id:
                errors.append(f"El padre del hijo {child_id} no coincide con {item_id}.")
    return sorted(set(errors))


def scope_complete(state: dict) -> bool:
    scope = state.get("scope_analysis", {})
    items = scope.get("items", {})
    return (
        bool(items)
        and not validate_scope(scope, state["ticket"])
        and scope.get("status") == "CONFIRMED"
        and all(item.get("status") == "DONE" for item in items.values())
    )


def blocked_scope_items(state: dict) -> list[str]:
    return [
        item_id
        for item_id, item in state.get("scope_analysis", {}).get("items", {}).items()
        if item.get("status") == "BLOCKED"
    ]


def previous_done(state: dict, phase: str) -> bool:
    index = PHASES.index(phase)
    return all(
        state["phases"][previous]["status"] == "DONE"
        for previous in PHASES[:index]
    )


def print_state(path: Path, state: dict) -> None:
    print(f"Ticket: {state['ticket']}")
    print(f"Proyecto: {state['project']}")
    print(f"Registro: {path}")
    print(f"Ticket context: {'COMPLETE' if context_complete(state) else 'INCOMPLETE'}")
    scope = state.get("scope_analysis", {})
    scope_errors = validate_scope(scope, state["ticket"])
    scope_label = "COMPLETE" if scope_complete(state) else ("INVALID" if scope_errors else scope.get("status", "PENDING"))
    print(f"Scope analysis: {scope_label} ({len(scope.get('items', {}))} nodos)")
    print()
    for phase in PHASES:
        item = state["phases"][phase]
        detail = item["evidence"] or item["reason"] or ""
        suffix = f" — {detail}" if detail else ""
        print(f"[{item['status']:^11}] {phase}{suffix}")


def print_compact(path: Path, state: dict) -> None:
    phases = state["phases"]
    done = sum(item["status"] == "DONE" for item in phases.values())
    active = [name for name, item in phases.items() if item["status"] == "IN_PROGRESS"]
    blocked = [name for name, item in phases.items() if item["status"] == "BLOCKED"]
    pending = [name for name, item in phases.items() if item["status"] == "PENDING"]
    parts = [f"{state['ticket']}: DONE {done}/{len(PHASES)}"]
    if active:
        parts.append(f"IN_PROGRESS={','.join(active)}")
    if blocked:
        parts.append(f"BLOCKED={','.join(blocked)}")
    if pending:
        parts.append(f"PENDING={','.join(pending)}")
    parts.append(f"state={path}")
    parts.append(
        f"ticket_context={'COMPLETE' if context_complete(state) else 'INCOMPLETE'}"
    )
    parts.append(
        f"scope={'COMPLETE' if scope_complete(state) else state.get('scope_analysis', {}).get('status', 'PENDING')}"
    )
    print(" | ".join(parts))


def cmd_init(ticket: str) -> int:
    path = state_path(ticket)
    if path.exists():
        _, state = load(ticket)
        print_compact(path, state)
        return 0
    state = new_state(ticket)
    save(path, state)
    print_compact(path, state)
    return 0


def cmd_show(ticket: str, compact: bool) -> int:
    path, state = load(ticket)
    if compact:
        print_compact(path, state)
    else:
        print_state(path, state)
    return 0


def cmd_start(ticket: str, phase: str) -> int:
    path, state = load(ticket)
    validate_state(state)
    if phase in ("analizar-alcance", "entrevistar") and not context_complete(state):
        raise RuntimeError(
            f"No se puede iniciar '{phase}': ticket_context está incompleto. "
            "Completa ID, título y descripción confirmados primero."
        )
    if phase == "entrevistar" and not scope_complete(state):
        raise RuntimeError(
            "No se puede iniciar 'entrevistar' como fase siguiente: scope_analysis no está completo. "
            "Durante 'analizar-alcance', invoca $entrevistar para resolver nodos BLOCKED."
        )
    item = state["phases"][phase]
    if not previous_done(state, phase):
        raise RuntimeError(
            f"No se puede iniciar '{phase}': hay una fase anterior sin DONE."
        )
    active = [
        name
        for name, candidate in state["phases"].items()
        if candidate["status"] == "IN_PROGRESS" and name != phase
    ]
    if active:
        raise RuntimeError(f"Ya existe una fase IN_PROGRESS: {active[0]}")
    if item["status"] == "DONE":
        raise RuntimeError(f"La fase '{phase}' ya está DONE.")
    item.update(
        status="IN_PROGRESS", evidence=None, reason=None, updated_at=now()
    )
    save(path, state)
    print(f"{ticket}: {phase}=IN_PROGRESS")
    return 0


def cmd_done(
    ticket: str,
    phase: str,
    evidence: str,
    jira_read: bool,
    user_approved: bool,
) -> int:
    path, state = load(ticket)
    validate_state(state)
    item = state["phases"][phase]
    if item["status"] != "IN_PROGRESS":
        raise RuntimeError(
            f"La fase '{phase}' debe estar IN_PROGRESS antes de marcarla DONE."
        )
    if not previous_done(state, phase):
        raise RuntimeError(
            f"No se puede terminar '{phase}': hay una fase anterior sin DONE."
        )
    if not evidence.strip():
        raise RuntimeError("Se requiere evidencia no vacía.")
    if phase == "ticket":
        if not context_complete(state):
            raise RuntimeError(
                "La fase 'ticket' requiere ticket_context completo: ID, título y descripción confirmados."
            )
        source = state["ticket_context"]["id"].get("source")
        if jira_read and source != "jira":
            raise RuntimeError(
                "--jira-read requiere que ticket_context tenga origen 'jira'."
            )
        if not jira_read and source != "user":
            raise RuntimeError(
                "Sin --jira-read, ticket_context debe tener origen 'user'."
            )
    if phase == "aprobacion" and not user_approved:
        raise RuntimeError(
            "La fase 'aprobacion' requiere --user-approved tras un OK explícito."
        )
    if phase == "analizar-alcance" and not scope_complete(state):
        pending = [
            item_id
            for item_id, scope_item in state.get("scope_analysis", {}).get("items", {}).items()
            if scope_item.get("status") != "DONE"
        ]
        raise RuntimeError(
            "La fase 'analizar-alcance' requiere todos los nodos DONE. "
            f"Pendientes: {', '.join(pending) or 'scope_analysis vacío'}."
        )
    item.update(
        status="DONE",
        evidence=evidence.strip(),
        reason=None,
        updated_at=now(),
    )
    save(path, state)
    print(f"{ticket}: {phase}=DONE")
    return 0


def cmd_context(
    ticket: str,
    context_id: str,
    title: str,
    description: str,
    source: str,
) -> int:
    path, state = load(ticket)
    if state["phases"]["ticket"]["status"] != "IN_PROGRESS":
        raise RuntimeError(
            "ticket_context solo puede completarse mientras la fase 'ticket' está IN_PROGRESS."
        )
    normalized_id = normalize_ticket(context_id)
    if normalized_id != ticket:
        raise RuntimeError(
            f"El ID del ticket context ({normalized_id}) no coincide con {ticket}."
        )
    if not title.strip() or not description.strip():
        raise RuntimeError("ticket_context requiere título y descripción no vacíos.")
    context = state["ticket_context"]
    for field, value in (
        ("id", normalized_id),
        ("title", title.strip()),
        ("description", description.strip()),
    ):
        context[field] = {"value": value, "source": source, "confirmed": True}
    context["complete"] = True
    save(path, state)
    print(f"{ticket}: ticket_context=COMPLETE source={source}")
    return 0


def validate_state(state: dict) -> None:
    errors = validate_scope(state.get("scope_analysis", {}), state["ticket"])
    phases = state.get("phases")
    if not isinstance(phases, dict):
        errors.append("phases debe ser un objeto.")
        phases = {}
    missing_phases = [phase for phase in PHASES if phase not in phases]
    errors.extend(f"Falta la fase {phase}." for phase in missing_phases)
    valid_statuses = {"PENDING", "IN_PROGRESS", "BLOCKED", "DONE"}
    active = 0
    for phase in PHASES:
        item = phases.get(phase)
        if not isinstance(item, dict):
            errors.append(f"La fase {phase} debe ser un objeto.")
            continue
        status = item.get("status")
        if status not in valid_statuses:
            errors.append(f"La fase {phase} tiene status inválido.")
        if status == "IN_PROGRESS":
            active += 1
        if status == "DONE" and not str(item.get("evidence") or "").strip():
            errors.append(f"La fase {phase} está DONE sin evidencia.")
        if status == "BLOCKED" and not str(item.get("reason") or "").strip():
            errors.append(f"La fase {phase} está BLOCKED sin motivo.")
    if active > 1:
        errors.append("Existe más de una fase IN_PROGRESS.")
    if state.get("ticket_context", {}).get("complete") is True and not context_complete(state):
        errors.append("ticket_context está marcado como completo pero sus datos no están confirmados.")
    if errors:
        raise RuntimeError("Estado inválido: " + " | ".join(errors))


def cmd_scope(ticket: str, analysis_json: str) -> int:
    path, state = load(ticket)
    if state["phases"]["analizar-alcance"]["status"] != "IN_PROGRESS":
        raise RuntimeError("scope_analysis solo puede actualizarse mientras analizar-alcance está IN_PROGRESS.")
    try:
        document = json.loads(analysis_json)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"JSON de scope_analysis inválido: {error}") from error
    if not isinstance(document, dict):
        raise RuntimeError("El documento de scope_analysis debe ser un objeto.")
    required = {"status", "root", "items"}
    missing = sorted(required - set(document))
    if missing:
        raise RuntimeError(f"scope_analysis requiere: {', '.join(missing)}.")
    if document["root"] != ticket:
        raise RuntimeError(f"scope_analysis.root debe ser {ticket}.")
    errors = validate_scope(document, ticket)
    if errors:
        raise RuntimeError("scope_analysis inválido: " + " | ".join(errors))
    if document["status"] not in ("IN_PROGRESS", "CONFIRMED"):
        raise RuntimeError("scope_analysis.status debe ser IN_PROGRESS o CONFIRMED.")
    if document["status"] == "CONFIRMED" and not all(
        item.get("status") == "DONE" for item in document["items"].values()
    ):
        raise RuntimeError("scope_analysis solo puede CONFIRMED con todos los nodos DONE.")
    document["version"] = 1
    document["updated_at"] = now()
    state["scope_analysis"] = document
    save(path, state)
    print(f"{ticket}: scope_analysis={document['status']} nodes={len(document['items'])}")
    return 0


def cmd_validate(ticket: str) -> int:
    path, state = load(ticket)
    validate_state(state)
    print(f"{ticket}: VALID state={path}")
    return 0


def cmd_block(ticket: str, phase: str, reason: str) -> int:
    path, state = load(ticket)
    item = state["phases"][phase]
    if item["status"] == "DONE":
        raise RuntimeError(f"No se puede bloquear '{phase}': ya está DONE.")
    if not reason.strip():
        raise RuntimeError("Se requiere un motivo no vacío.")
    item.update(
        status="BLOCKED",
        evidence=None,
        reason=reason.strip(),
        updated_at=now(),
    )
    save(path, state)
    print(f"{ticket}: {phase}=BLOCKED — {reason.strip()}")
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(
        description="Control secuencial del flujo $cocinar."
    )
    commands = root.add_subparsers(dest="command", required=True)

    init = commands.add_parser("init")
    init.add_argument("ticket")

    show = commands.add_parser("show")
    show.add_argument("ticket")
    show.add_argument("--compact", action="store_true")

    start = commands.add_parser("start")
    start.add_argument("ticket")
    start.add_argument("phase", choices=PHASES)

    done = commands.add_parser("done")
    done.add_argument("ticket")
    done.add_argument("phase", choices=PHASES)
    done.add_argument("--evidence", required=True)
    done.add_argument("--jira-read", action="store_true")
    done.add_argument("--user-approved", action="store_true")

    context = commands.add_parser("context")
    context.add_argument("ticket")
    context.add_argument("--id", required=True, dest="context_id")
    context.add_argument("--title", required=True)
    context.add_argument("--description", required=True)
    context.add_argument("--source", choices=("jira", "user"), required=True)

    scope = commands.add_parser("scope")
    scope.add_argument("ticket")
    scope.add_argument("--json", required=True, dest="analysis_json")

    validate = commands.add_parser("validate")
    validate.add_argument("ticket")

    block = commands.add_parser("block")
    block.add_argument("ticket")
    block.add_argument("phase", choices=PHASES)
    block.add_argument("--reason", required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        ticket = normalize_ticket(args.ticket)
        if args.command == "init":
            return cmd_init(ticket)
        if args.command == "show":
            return cmd_show(ticket, args.compact)
        if args.command == "start":
            return cmd_start(ticket, args.phase)
        if args.command == "done":
            return cmd_done(
                ticket,
                args.phase,
                args.evidence,
                args.jira_read,
                args.user_approved,
            )
        if args.command == "context":
            return cmd_context(
                ticket,
                args.context_id,
                args.title,
                args.description,
                args.source,
            )
        if args.command == "scope":
            return cmd_scope(ticket, args.analysis_json)
        if args.command == "validate":
            return cmd_validate(ticket)
        if args.command == "block":
            return cmd_block(ticket, args.phase, args.reason)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
