---
name: cocinar
description: Cargar un ticket de Jira y entregar su contexto a /sdd para continuar el flujo de desarrollo, planificar tareas y crear sus subtareas en Jira. Usar cuando el usuario pida cocinar o implementar un ticket Jira de punta a punta.
---

# Cocinar un ticket de Jira

Esta skill es un adaptador entre Jira y `/sdd`. Su única responsabilidad es
obtener el contexto verificado del ticket y entregarlo a `/sdd`. No mantiene un
estado local ni duplica el flujo de análisis, entrevistas, planificación o
implementación de `/sdd`. También transmite las reglas para que el plan de
implementación quede dividido en unidades lógicas y trazado en Jira.

## Entrada

- Aceptar exactamente un ID de Jira.
- Normalizarlo a mayúsculas y validar el formato `^[A-Z][A-Z0-9]+-[0-9]+$`.
- Si falta o es inválido, pedir únicamente un ID válido y detenerse.

## Obtener el contexto de Jira

1. Invocar `/consultar-ticket` con el ID normalizado.
2. Usar el resultado como fuente de verdad. Debe contener `ticket_id`, `title`
   y `description`, y el ID debe coincidir con el solicitado.
3. Invocar `/consultar-subtareas` para consultar las subtareas existentes. Si
   no hay subtareas, usar `subtasks: []`.
4. No consultar Jira directamente desde esta skill, no usar herramientas MCP
   de Atlassian y no inventar datos ausentes.
5. Conservar exactamente el manejo de errores definido por las skills de
   consulta: autenticación, conexión, ticket inexistente o herramientas
   faltantes bloquean el traspaso y se informan brevemente.

Las subtareas existentes son contexto del ticket padre. Incluirlas en el
mensaje de entrada para que `/sdd` evite duplicar el trabajo que ya representan.

## Traspaso a `/sdd`

Solo después de cargar correctamente el ticket y sus subtareas, invocar
`/sdd` con una descripción en lenguaje natural que incluya este contexto y las
reglas siguientes para el plan de implementación:

```text
Trabajar sobre el ticket de Jira <TICKET_ID>.

Origen: Jira. Conservar <TICKET_ID> como referencia trazable durante todo el
flujo, pero no usarlo obligatoriamente como slug de la feature.

Título:
<title>

Descripción:
<description>

Subtareas existentes del ticket padre (solo contexto; no iniciar flujos
independientes):
- <subtask_id>: <subtask_title>

Instrucciones para el plan de implementación:
- Dividir el trabajo por unidades lógicas verticales, con un objetivo y una
  verificación propios; no dividir solo por capas ni solo para alcanzar un
  número.
- Apuntar a un cambio de hasta 300 líneas en el diff por tarea: contar las
  líneas agregadas y borradas, incluir las pruebas y excluir lockfiles y
  archivos generados. Si una unidad lógica indivisible supera 300, explicar el
  motivo en su descripción y mantener el límite duro vigente de 500 líneas.
- Reutilizar las subtareas existentes que ya representen el mismo trabajo; no
  crear duplicados. Si la correspondencia no es clara, resolverla antes de
  crear otra subtarea.
- Después de revisar y aprobar el plan —o si ya estaba aprobado—, invocar
  `/crear-jira-issue` para crear una subtarea por cada tarea nueva, bajo
  <TICKET_ID>. Respetar la entrevista y la confirmación explícita de ese skill;
  no ejecutar el plan hasta que las subtareas necesarias estén creadas.
- No crear subtareas mediante llamadas directas a Jira ni omitir los controles
  de `/crear-jira-issue`. Si una creación falla, detener la ejecución del plan e
  informar qué tareas quedaron sin subtarea.
```

Entregar el contexto completo, sin resumir ni reinterpretar el título o la
descripción obtenidos de Jira. `/sdd` debe resolver la feature, detectar el
paso pendiente y mantener el estado posterior según su propia skill. El límite
duro vigente sigue siendo de 500 líneas.

Después de invocar `/sdd`, terminar la participación de `cocinar`: no mantener
estado propio, modificar código, crear ramas, hacer commits, abrir pull
requests ni crear tickets directamente. `/sdd` coordina el trabajo y
`/crear-jira-issue` conserva la confirmación explícita antes de cada escritura
en Jira.
