---
name: cocinar
description: Cargar un ticket de Jira y entregar su contexto a sdd para continuar el flujo completo de desarrollo. Usar cuando el usuario pida cocinar o implementar un ticket Jira de punta a punta.
---

# Cocinar un ticket de Jira

Esta skill es un adaptador entre Jira y `sdd`. Su única responsabilidad es
obtener el contexto verificado del ticket y entregarlo a `sdd`. No mantiene un
estado local ni duplica el flujo de análisis, entrevistas, planificación o
implementación de `sdd`.

## Entrada

- Aceptar exactamente un ID de Jira.
- Normalizarlo a mayúsculas y validar el formato `^[A-Z][A-Z0-9]+-[0-9]+$`.
- Si falta o es inválido, pedir únicamente un ID válido y detenerse.

## Obtener el contexto de Jira

1. Leer y seguir exactamente `/Users/ivanlynch/.codex/skills/consultar-ticket/SKILL.md`.
2. Ejecutar su implementación obligatoria con el ID normalizado:

   ```bash
   python3 /Users/ivanlynch/.codex/skills/consultar-ticket/scripts/get_ticket.py <TICKET_ID>
   ```

3. Usar el resultado como fuente de verdad. Debe contener `ticket_id`, `title`
   y `description`, y el ID debe coincidir con el solicitado.
4. Leer y seguir `/Users/ivanlynch/.agents/skills/consultar-subtareas/SKILL.md`
   para consultar las subtareas existentes. Si no hay subtareas, usar
   `subtasks: []`.
5. No consultar Jira directamente desde esta skill, no usar herramientas MCP
   de Atlassian y no inventar datos ausentes.
6. Conservar exactamente el manejo de errores definido por las skills de
   consulta: autenticación, conexión, ticket inexistente o herramientas
   faltantes bloquean el handoff y se informan brevemente.

Las subtareas son contexto del ticket padre. No crear features, subtareas ni
tickets nuevos a partir de ellas.

## Handoff a `sdd`

Solo después de cargar correctamente el ticket y sus subtareas, invocar
`sdd` con una descripción en lenguaje natural que incluya este contexto:

```text
Trabajar sobre el ticket de Jira <TICKET_ID>.

Origen: Jira. Conservar <TICKET_ID> como referencia trazable durante todo el
flujo, pero no usarlo obligatoriamente como slug de la feature.

Título:
<title>

Descripción:
<description>

Subtareas existentes del ticket padre (solo contexto; no ejecutar flujos
independientes):
- <subtask_id>: <subtask_title>
```

Entregar el contexto completo, sin resumir ni reinterpretar el título o la
descripción obtenidos de Jira. `sdd` debe resolver la feature, detectar el
paso pendiente y mantener el estado posterior según su propia skill.

Después de invocar `sdd`, terminar la participación de `cocinar`. No ejecutar
`workflow_state.sh`, no crear branches, no modificar código, no hacer commits,
no abrir pull requests y no pedir una aprobación adicional: esas decisiones
pertenecen al flujo delegado en `sdd`.
