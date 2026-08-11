---
name: cocinar
description: Preparar e implementar de extremo a extremo un ticket de Jira recibido como argumento, por ejemplo `/cocinar PROJ-1234`. Consultar el ticket y sus subtareas, analizar el alcance, aclarar requisitos, producir un plan interno en etapas pequeñas, obtener aprobación explícita, crear una branch, implementar cada etapa con tests y commits verificables, y abrir una pull request mediante la skill crear-pr. Usar cuando el usuario pida cocinar o implementar un ticket existente de punta a punta sin crear tickets adicionales.
---

# Cocinar un ticket de Jira

Ejecutar este flujo como una máquina de estados estricta. No empezar una fase si la anterior no está `DONE`. No marcar una fase como `DONE` por inferencia ni sin la evidencia exigida.

## Reglas invariables

- Aceptar exactamente un ID de Jira como entrada. Normalizarlo a mayúsculas y validar el formato `^[A-Z][A-Z0-9]+-[0-9]+$`. Si falta o es inválido, pedir únicamente un ID válido y detenerse.
- Ejecutar `<analizar-alcance-skill-dir>/scripts/workflow_state.sh` (el mismo script que usa `/analizar-alcance`) para registrar todos los cambios de estado — no bundlear una copia propia acá.
- Mantener como máximo una fase `IN_PROGRESS`.
- Ante un error o falta de información, marcar la fase `BLOCKED`, explicar el bloqueo y esperar al usuario cuando sea necesaria una decisión.
- No crear una branch, modificar código, ejecutar una implementación, hacer commits, subir cambios ni abrir una PR antes de que `aprobacion` esté `DONE`.
- Investigar hechos disponibles en Jira, el repositorio o las herramientas. Preguntar al usuario solamente por decisiones o información que no pueda descubrirse.
- Cocinar siempre el ticket recibido como unidad de trabajo. Las subtareas existentes son contexto; no crear subtareas ni tickets nuevos automáticamente.
- El plan de implementación es interno a este flujo. No invocar `/crear-ticket` para convertir sus etapas en issues de Jira.
- Cada etapa debe ser pequeña, verificable y terminar en un commit separado. Ejecutar tests y coverage cuando el proyecto ya los soporte; si no hay coverage configurado, registrar esa limitación sin introducir una herramienta nueva.
- Si una verificación o una etapa queda bloqueada, investigar primero las opciones disponibles en el proyecto y usar `/entrevistar` para agotarlas y obtener la decisión necesaria. No registrar deuda técnica ni cerrar la etapa por decisión unilateral.
- No ampliar el alcance silenciosamente.

## Economía de tokens y ejecución

- Mantener todos los mensajes, comentarios, planes y descripciones breves y directos. Evitar introducciones, recapitulaciones y explicaciones repetidas.
- Limitar cada actualización a uno o dos enunciados. Usar como máximo cinco viñetas cuando una lista sea necesaria.
- No pegar resultados completos de tests, logs, stack traces, diffs ni herramientas CLI en el chat.
- Para inspección local, usar búsquedas dirigidas y rangos pequeños: `rg` con patrones concretos, límites de coincidencias, `head`, `tail` o rangos de líneas. No leer archivos o logs grandes completos.
- Preferir flags silenciosos como `--quiet`, `--silent` o `--no-progress`. Si existe salida estructurada, seleccionar únicamente los campos necesarios.
- Cuando la herramienta permita limitar su salida, fijar un presupuesto máximo bajo, normalmente 1.000–2.000 tokens. Aumentarlo solo para un fragmento dirigido imprescindible.
- Redirigir cualquier salida potencialmente extensa a un archivo temporal. Leer solamente el exit code, el resumen y hasta 20 líneas relevantes alrededor del primer error o causa raíz.
- Para tests, logs, stack traces o comandos CLI que no puedan ejecutarse con salida acotada, dar al usuario un único comando exacto y corto para ejecutarlo. Pedir que devuelva solo el exit code y el fragmento relevante, nunca la salida completa.
- No delegar al usuario operaciones silenciosas necesarias para el flujo automatizado: controlador de estados, edición, Git, apertura de PR y login OAuth de Atlassian. La regla anterior aplica a diagnósticos o verificaciones ruidosas.
- Al informar una verificación, mostrar únicamente: nombre, `PASS`/`FAIL`, exit code y una causa breve si falló.
- Mantener comentarios de código y descripciones de PR concisos. No comentar lo obvio.

## Fases obligatorias

### 0. Inicializar el registro

Ejecutar:

```bash
<analizar-alcance-skill-dir>/scripts/workflow_state.sh init <TICKET_ID>
<analizar-alcance-skill-dir>/scripts/workflow_state.sh show <TICKET_ID> --compact
```

Si el registro ya existe, mostrarlo y reanudar solamente desde la primera fase no terminada. `<skill-dir>` es el directorio que contiene este `SKILL.md`.

### 1. `ticket`: delegar la consulta a la skill correcta de `consultar-ticket`

1. Marcar `ticket` como `IN_PROGRESS`.
2. Leer y seguir exactamente `/Users/ivanlynch/.codex/skills/consultar-ticket/SKILL.md`. Ejecutar esa skill con `<TICKET_ID>` normalizado; su implementación obligatoria es `python3 /Users/ivanlynch/.codex/skills/consultar-ticket/scripts/get_ticket.py <TICKET_ID>`.
3. Usar el JSON devuelto como fuente de verdad. Debe contener únicamente `ticket_id`, `title` y `description`; verificar que `ticket_id` coincida con el ticket solicitado.
4. No consultar Jira directamente, no usar herramientas MCP de Atlassian desde `/cocinar`, no ejecutar login y no inventar datos faltantes.
5. Si la skill `/Users/ivanlynch/.codex/skills/consultar-ticket/SKILL.md` devuelve un error de autenticación, conexión o ticket inexistente, respetar su flujo y marcar `ticket` como `BLOCKED` con el error breve. No duplicar sus reintentos ni pedir credenciales desde `/cocinar`.
6. Si la consulta es exitosa, registrar el contexto antes de terminar la fase:

   ```bash
   <analizar-alcance-skill-dir>/scripts/workflow_state.sh context <TICKET_ID> --id "<ticket_id>" --title "<title>" --description "<description>" --source jira
   <analizar-alcance-skill-dir>/scripts/workflow_state.sh done <TICKET_ID> ticket --jira-read --evidence "<TICKET_ID>: contexto cargado por consultar-ticket"
   ```

7. Consultar las subtareas existentes con `/consultar-subtareas <TICKET_ID>` y conservar su JSON como contexto adicional. Si no hay subtareas, continuar con `subtasks: []`; no crear ninguna.

### 2. `analizar-alcance`: evaluar tamaño y división

1. Verificar con `<analizar-alcance-skill-dir>/scripts/workflow_state.sh show <TICKET_ID> --compact` que `ticket_context=COMPLETE`.
2. Marcar `analizar-alcance` como `IN_PROGRESS`.
3. Leer por completo y seguir `/analizar-alcance`.
4. Evaluar independencia, tamaño, testabilidad, criterios de aceptación, dependencias y señales de división.
5. Si faltan decisiones, usar `/entrevistar` con una sola pregunta por turno y una recomendación breve.
6. Si el ticket requiere división, proponer subtareas verticales, independientes y testeables.
7. Persistir el árbol completo con el controlador de estado (texto plano, sin JSON — ver `/analizar-alcance`). Cada nodo debe tener `title`, `parent`, `status` y `verdict`; las hojas `APTO_PARA_IMPLEMENTAR` además necesitan `acceptance_criteria`.
8. Mantener `analizar-alcance` como `IN_PROGRESS` mientras exista cualquier nodo `BLOCKED`, `PENDING` o `IN_PROGRESS`.
9. Si un nodo queda `BLOCKED`, invocar `/entrevistar` dentro de esta fase: hacer una pregunta por turno, incluir una recomendación, esperar la respuesta, actualizar el nodo y volver a analizarlo. No iniciar todavía la fase global `entrevistar`.
10. Si un nodo requiere división, agregar sus subtareas al árbol y dejar el padre en `DONE` con veredicto `REQUIERE_DIVISION`. Analizar cada hijo recursivamente. Repetir hasta que cada nodo sea `DONE`; las hojas deben tener veredicto `APTO_PARA_IMPLEMENTAR` y los padres divididos `REQUIERE_DIVISION`.
11. Después de cada actualización, ejecutar:

    ```bash
    <analizar-alcance-skill-dir>/scripts/workflow_state.sh validate <TICKET_ID>
    ```

12. Registrar cada nodo con los comandos granulares de `/analizar-alcance` (`scope-set-objective`, `scope-add-item`, `scope-set-item`, `scope-set-criteria`) — no existe un comando único que reemplace todo el árbol de una vez. Para cerrar el análisis, ejecutar `scope-confirm <TICKET_ID>` recién cuando todos los nodos estén `DONE`.
13. No implementar ni crear branches. Marcar la fase como `DONE` solo después de que `scope-confirm` funcione (equivale a `CONFIRMED` con todos los nodos `DONE`).

### 3. `entrevistar`: aclarar el alcance y cerrar decisiones

1. El controlador impide iniciar esta fase si `ticket_context` no está completo, si `analizar-alcance` no está `DONE` o si `scope_analysis` no está confirmado. Los bloqueos del árbol se resuelven dentro de `analizar-alcance` mediante `/entrevistar`.
2. Marcar `entrevistar` como `IN_PROGRESS`.
3. Leer por completo y seguir el skill global `entrevistar`, normalmente ubicado en `../entrevistar/SKILL.md`. Si no puede localizarse, bloquear la fase; no imitarlo de memoria.
4. Usar como contexto la información verificada de Jira o proporcionada por el usuario, el análisis de alcance y el repositorio.
5. Hacer una sola pregunta por turno, incluir una recomendación y esperar la respuesta.
6. Investigar hechos en vez de preguntarlos. Plantear al usuario todas las decisiones, dependencias, ambigüedades y criterios faltantes.
7. No marcar la fase como `DONE` hasta que el usuario confirme expresamente que existe entendimiento compartido.

### 4. `guia-proyecto`: encontrar el flujo local de implementación

1. Marcar `guia-proyecto` como `IN_PROGRESS`.
2. Desde la raíz del proyecto, buscar primero instrucciones, skills, comandos y Markdown locales relacionados con implementar features o tickets. Revisar, como mínimo:
   - `AGENTS.md` y `AGENTS.override.md`;
   - `.agents/skills/**/SKILL.md`;
   - `.codex/**`, directorios de comandos o prompts;
   - `SKILL.md`, `PLANS.md`, `CONTRIBUTING.md` y otros archivos Markdown;
   - referencias a “feature”, “implementación”, “ticket”, “development workflow” o equivalentes.
3. Leer y obedecer la guía aplicable más específica. Registrar las rutas encontradas como evidencia.
4. Si no existe una guía local, indicarlo explícitamente. La fase puede terminar, pero la fase siguiente deberá crear un Markdown temporal con el plan.

### 5. `plan`: producir plan interno por etapas y deuda técnica

1. Marcar `plan` como `IN_PROGRESS`.
2. Invocar `/plan --internal` con la guía local encontrada; `/plan` lee el alcance confirmado directamente del registro de `/analizar-alcance`, no hace falta pasárselo. No reconstruir el alcance ni editar manualmente el estado del plan.
3. Seguir `/plan` para dividir el trabajo en tareas ejecutables, con resultado observable, verificación concreta y orden por dependencia.
4. En modo `--internal`, `/plan` debe redactar y persistir directamente el título y la descripción de cada etapa mediante `plan_state.sh`; no invocar `/crear-ticket` ni esperar confirmaciones por etapa.
5. No implementar nada. Marcar la fase como `DONE` solamente cuando `/plan` devuelva `PLAN_COMPLETE`, haya creado el archivo ejecutable del plan y todas las tareas estén persistidas como `READY`.

### 6. `aprobacion`: pedir permiso y detenerse

1. Marcar `aprobacion` como `IN_PROGRESS`.
2. Presentar al usuario el plan, las tareas pequeñas, las verificaciones y la deuda técnica.
3. Preguntar exactamente: **“¿Me das el OK para empezar la implementación?”**
4. Terminar el turno y esperar. El silencio, una respuesta ambigua o la aprobación de una fase anterior no cuentan como autorización.
5. Solo ante un `OK` explícito posterior, marcar la fase como `DONE` usando `--user-approved` y conservar como evidencia la respuesta del usuario.

```bash
<analizar-alcance-skill-dir>/scripts/workflow_state.sh done <TICKET_ID> aprobacion --user-approved --evidence "Aprobación explícita del usuario: <respuesta>"
```

Antes de cualquier acción de implementación, ejecutar `show --compact` y comprobar que `aprobacion` figura como `DONE`. Si no figura así, detenerse.

### 7. `branch`: crear la branch exacta

1. Marcar `branch` como `IN_PROGRESS`.
2. Inspeccionar el estado y la branch actuales sin descartar ni sobrescribir cambios del usuario.
3. Crear una branch cuyo nombre sea exactamente el ID normalizado del ticket, por ejemplo `PROJ-1234`.
4. Si ya existe, no borrarla ni reemplazarla. Si no se está ya en ella, pedir al usuario cómo proceder porque no se permite inventar otro nombre.
5. Verificar la branch activa antes de marcar la fase como `DONE`.

### 8. `implementacion`: ejecutar y verificar tareas

1. Marcar `implementacion` como `IN_PROGRESS`.
2. Invocar `/implementar-plan <plan-file> --commit-each` con el archivo ejecutable creado por `/plan`.
3. Dejar que `/implementar-plan` invoque `/implementar-tarea` una tarea por vez y marque cada tarea como `DONE` en el archivo únicamente después de recibir evidencia `DONE`.
4. Después de cada tarea `DONE`, verificar tests, coverage cuando exista y el diff; crear un commit pequeño y separado antes de continuar con la siguiente etapa. Si alguna verificación falla, detener la etapa, investigar las opciones disponibles y usar `/entrevistar` antes de decidir cómo continuar. Mantener los cambios dentro del alcance aprobado. Informar cualquier necesidad de ampliar el alcance y esperar autorización.
5. Marcar la fase como `DONE` solo cuando `/implementar-plan` devuelva `PLAN_COMPLETE`; si devuelve `BLOCKED`, conservar la fase bloqueada con la evidencia.

### 9. `pr`: preparar y abrir la pull request

1. Marcar `pr` como `IN_PROGRESS`.
2. Invocar `/crear-pr` con el ID y el título verificado de Jira, la branch, los commits y las verificaciones.
3. Dejar que `/crear-pr` busque las instrucciones y la plantilla aplicable del repositorio, prepare la descripción y valide el título.
4. No abrir la PR si el título no cumple exactamente `[<JIRA TICKET>] <Título del ticket de Jira>`.
5. Informar el enlace de la PR, verificaciones realizadas y deuda técnica real generada o pendiente. Marcar la fase como `DONE` únicamente después de confirmar que la PR existe.

## Cierre

Consultar el registro final con `workflow_state.sh show <TICKET_ID> --compact`, pero no copiarlo completo al chat. Informar solamente fases incompletas o confirmar que todas están `DONE`. Si existe una fase `BLOCKED`, indicar en una frase el siguiente paso exacto.
