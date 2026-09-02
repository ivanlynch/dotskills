#!/usr/bin/env python3
"""Return the title and description of a Jira issue as JSON."""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ISSUE_PATTERN = re.compile(r"^[A-Z][A-Z0-9]+-[0-9]+$")
AUTH_REQUIRED = 2
NOT_FOUND = 3
REQUEST_FAILED = 4


class JiraError(Exception):
    """Expected Jira failure with a stable CLI exit code."""

    def __init__(self, message: str, exit_code: int) -> None:
        super().__init__(message)
        self.exit_code = exit_code


def adf_to_text(value: object) -> str:
    """Convert Jira Atlassian Document Format to readable plain text."""
    if isinstance(value, str):
        return value
    if not isinstance(value, dict):
        return ""

    node_type = value.get("type")
    parts: list[str] = []
    if node_type == "hardBreak":
        parts.append("\n")
    text = value.get("text")
    if isinstance(text, str):
        parts.append(text)
    content = value.get("content")
    if isinstance(content, list):
        parts.extend(adf_to_text(child) for child in content)
        if node_type in {"paragraph", "heading", "listItem", "blockquote", "codeBlock"}:
            parts.append("\n")
    return "".join(parts)


def required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise JiraError(f"AUTH_REQUIRED: falta {name}", AUTH_REQUIRED)
    return value


def fetch_ticket(ticket_id: str) -> dict[str, str]:
    ticket_id = ticket_id.upper()
    if not ISSUE_PATTERN.fullmatch(ticket_id):
        raise JiraError("El ticket-id debe tener formato PROJECT-123", REQUEST_FAILED)

    base_url = required_env("JIRA_BASE_URL").rstrip("/")
    email = required_env("JIRA_EMAIL")
    token = required_env("JIRA_API_TOKEN")
    credentials = base64.b64encode(f"{email}:{token}".encode()).decode()
    request = Request(
        f"{base_url}/rest/api/3/issue/{ticket_id}?fields=summary,description",
        headers={
            "Accept": "application/json",
            "Authorization": f"Basic {credentials}",
            "User-Agent": "codex-jira-skill",
        },
    )

    try:
        with urlopen(request, timeout=20) as response:
            payload = json.load(response)
    except HTTPError as error:
        if error.code in {401, 403}:
            raise JiraError(
                f"AUTH_REQUIRED: Jira rechazó las credenciales ({error.code})",
                AUTH_REQUIRED,
            ) from error
        if error.code == 404:
            raise JiraError(f"No se encontró el ticket {ticket_id}", NOT_FOUND) from error
        raise JiraError(f"Jira respondió con HTTP {error.code}", REQUEST_FAILED) from error
    except URLError as error:
        raise JiraError(f"No se pudo conectar con Jira: {error.reason}", REQUEST_FAILED) from error
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        raise JiraError("Jira devolvió una respuesta inválida", REQUEST_FAILED) from error

    fields = payload.get("fields") or {}
    title = fields.get("summary")
    if not isinstance(title, str) or not title.strip():
        raise JiraError("Jira no devolvió el título del ticket", REQUEST_FAILED)
    description = adf_to_text(fields.get("description")).strip()
    return {"ticket_id": ticket_id, "title": title.strip(), "description": description}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ticket_id", help="ID de Jira, por ejemplo DTCZE-1234")
    args = parser.parse_args()
    try:
        result = fetch_ticket(args.ticket_id)
    except JiraError as error:
        print(str(error), file=sys.stderr)
        return error.exit_code
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
