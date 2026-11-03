---
name: crear-jira-issue
description: Entrevista al usuario, genera el título y la descripción de una tarea en portugués de Brasil y la crea en Jira como Technical Task independiente o como subtarea de un ticket existente. Usar cuando haya que definir y registrar trabajo en Jira.
---

# Crear tareas en Jira

Este skill combina el flujo de `/crear-ticket` con la creación efectiva del issue en Jira. La entrevista y la confirmación son obligatorias antes de realizar la escritura.

## Configuración fija

- Proyecto predeterminado para tareas independientes: `DTCZE`.
- Parent predeterminado para una tarea independiente: `DTCZE-12424` (Epic de DTC Zé Courier - BAU).
- Tipo predeterminado para una tarea independiente: `Technical Task` (`id: 11737`).
- Board de referencia: `https://ab-inbev.atlassian.net/jira/software/c/projects/DTCZE/boards/54142/backlog`.
- Team Name fijo de creación: `ZE_Last_Mile` (`customfield_13230`, opción ID `61436`).

No usar el board para crear el ticket. En el modo independiente, la API REST crea el proyecto, tipo, parent y Team Name; el campo Sprint queda vacío.

### Modo de subtarea

Cuando el trabajo provenga del plan de implementación de `/sdd`, crear una
subtarea bajo el ticket Jira recibido, no bajo el parent predeterminado:

- Pasar el ticket como `--parent-key` al script. El script obtiene su proyecto
  y consulta los tipos de tarea habilitados para el usuario.
- Jira debe devolver exactamente un tipo de subtarea para elegirlo
  automáticamente. Si hay varios, presentar sus nombres e IDs y preguntarle al
  usuario cuál usar; pasar la elección con `--subtask-issue-type-id`. Si no hay
  ninguno disponible, detenerse sin crear el ticket.
- No crear subtareas bajo otra subtarea. Si el ticket recibido ya es una
  subtarea, detenerse e informar el motivo.
- Copiar el `Team Name` del parent si tiene uno. Jira toma el Sprint del parent;
  el script no lo asigna de nuevo ni agrega la subtarea al sprint mediante la
  API Agile.
- La descripción y el título salen de la tarea aprobada del plan, sin inventar
  criterios ni convertir una tarea vertical en una descripción genérica.

La creación independiente conserva su parent, tipo y Team Name
predeterminados. No asignar un Sprint ni depender de valores predeterminados o
automatizaciones de Jira para esos campos.

## Flujo de entrevista

Usar `/entrevistar` como parte obligatoria del flujo:

1. Hacer una sola pregunta por turno.
2. Mantener cada pregunta breve y directa.
3. Incluir una recomendación concreta después de cada pregunta.
4. Esperar la respuesta antes de continuar.
5. Investigar hechos disponibles en el workspace en lugar de preguntarlos.
6. Plantear al usuario las decisiones, preferencias y supuestos que no puedan descubrirse.
7. No generar ni crear el ticket final hasta alcanzar un entendimiento compartido y recibir confirmación explícita.

Si se invoca para una tarea de un plan aprobado por `/sdd`, usar el título,
alcance, dependencias y criterios de aceptación de esa tarea como fuente de
verdad. Seguir entrevistando si falta una decisión necesaria y pedir la
confirmación explícita antes de crear cada subtarea.

## Información que debe cerrarse

Confirmar o resolver:

- Objetivo principal de la tarea.
- Módulo o componente afectado.
- Contexto y motivación.
- Alcance y fuera de alcance.
- Criterios de aceptación verificables.
- Detalles técnicos, dependencias y restricciones relevantes.
- Recursos, documentación, logs o diseños disponibles.

Si un dato no es esencial, declararlo como supuesto o `Não definido` en lugar de bloquear el flujo.

## Resultado de la entrevista

Antes de crear el issue, presentar en español el entendimiento compartido y pedir confirmación explícita. Después de la confirmación, generar el título en portugués de Brasil (`pt-BR`) y completar mecánicamente la descripción con `scripts/render_description.sh` usando `templates/technical-task.md`.

Para toda tarea relacionada con frontend —incluyendo pantallas, componentes, hooks, navegación, estilos, pruebas o configuración de la aplicación cliente— el título debe comenzar exactamente con `[Front] `. Si el prefijo ya existe, no duplicarlo. Para tareas que no sean de frontend, no agregarlo.

```markdown
## Contexto

[Contexto breve do problema, com a evidência disponível.]

## Problema

[Problema técnico ou de negócio, com a evidência disponível.]

## Objetivo

[Resultado esperado, em uma frase direta.]

## Escopo

- [Entrega ou comportamento incluído.]
- [Entrega ou comportamento incluído.]

## Critérios de aceitação

- [ ] [Critério verificável.]
- [ ] [Critério verificável.]

## Fora de escopo

- [Item explicitamente excluído ou Jira relacionado.]

## Recursos

- [Issue, RFC, documentação ou outro recurso relacionado.]
```

La plantilla ejecutable está en `templates/technical-task.md`. Para evitar errores de estructura, guardar el contenido de cada sección en un archivo separado y ejecutar:

```bash
bash <skill-dir>/scripts/render_description.sh \
  --context-file /tmp/context.txt \
  --problem-file /tmp/problem.txt \
  --objective-file /tmp/objective.txt \
  --scope-file /tmp/scope.txt \
  --acceptance-file /tmp/acceptance.txt \
  --out-of-scope-file /tmp/out-of-scope.txt \
  --resources-file /tmp/resources.txt \
  --output-file /tmp/description.md
```

El script valida que los archivos no estén vacíos y que los encabezados aparezcan en el orden obligatorio. La IA puede redactar el contenido de las secciones durante la entrevista, pero no debe montar manualmente los encabezados ni insertar una sección `## Título` en la descripción.

Reglas de redacción para esta estructura:

- Mantener el formato simple, conciso y orientado a la entrega; evitar introducciones, justificaciones largas y lenguaje genérico.
- Usar exactamente las secciones `Contexto`, `Problema`, `Objetivo`, `Escopo`, `Critérios de aceitação`, `Fora de escopo` y `Recursos`, en ese orden.
- Preservar los nombres de archivos, campos, eventos, categorías, orígenes de error, productos y servicios tal como aparecen en el contexto técnico.
- Escribir criterios como resultados verificables. Mantener `[x]` cuando el usuario informe que el criterio ya se completó; usar `[ ]` cuando aún esté pendiente.
- Incluir rutas de archivos dentro de `Escopo` solo cuando hayan sido proporcionadas o identificadas en el workspace; no inventar rutas.
- Si no se informa ningún elemento fuera de alcance, escribir `- Não definido`.
- No incluir `## Título` dentro de la descripción ni las secciones `Descrição / User Story`, `Detalhes técnicos e considerações` o `Design / recursos`, salvo que el usuario lo solicite explícitamente.
- Para bugs, mantener la misma estructura compacta y adaptar `Contexto` para indicar comportamiento actual, comportamiento esperado, reproducción y evidencias.

## Crear el ticket o la subtarea

1. Guardar el título final y los archivos de sección aprobados en archivos temporales, sin incluir secretos. Ejecutar `scripts/render_description.sh` para producir la descripción final en Markdown. El script de creación convierte ese Markdown a Atlassian Document Format (ADF) antes de enviarla a Jira. No convertirla manualmente a JSON ni enviarla como texto plano.
2. Ejecutar una sola vez el script de esta skill. Para una tarea independiente:

   ```bash
   bash <skill-dir>/scripts/create_jira_issue.sh \
     --title-file "/ruta/al/titulo.txt" \
     --description-file "/ruta/a/la/descripcion.md"
   ```

   Para una subtarea, pasar el parent recibido. Si el script informa que hay
   varios tipos disponibles, preguntar cuál usar y repetir la consulta con el
   ID elegido, confirmando de nuevo el resumen final antes de crear:

   ```bash
   bash <skill-dir>/scripts/create_jira_issue.sh \
     --title-file "/ruta/al/titulo.txt" \
     --description-file "/ruta/a/la/descripcion.md" \
     --parent-key "$PARENT_KEY" \
     --subtask-issue-type-id "$SUBTASK_ISSUE_TYPE_ID"
   ```

3. Sin `--parent-key`, el script crea un `Technical Task` con parent `DTCZE-12424` y `Team Name = ZE_Last_Mile`. No asigna un Sprint.
4. Con `--parent-key`, el script consulta el ticket padre y los tipos de tarea disponibles. Crea una subtarea con el proyecto y el parent detectados; copia el `Team Name` del parent si existe y hereda su Sprint.
5. No reintentar automáticamente una creación fallida: una repetición podría duplicar el ticket. La consulta que informa varios tipos ocurre antes de crear; después de elegir uno, volver a confirmar el resumen y ejecutar el script una sola vez con el ID elegido. Si la respuesta a la creación es ambigua, consultar Jira antes de volver a crear.
6. Informar el JSON devuelto por el script y el enlace al ticket creado.

## Autenticación ausente o inválida

El script utiliza exit code `2` cuando faltan credenciales o Jira responde `401`/`403`. En ese caso:

- Detener la creación inmediatamente.
- No reintentar automáticamente.
- Explicar estos pasos, en este orden:

  1. ```bash
     export JIRA_BASE_URL="https://ab-inbev.atlassian.net"
     ```
  2. ```bash
     export JIRA_EMAIL="tu-email@ab-inbev.com"
     ```
  3. Crear un API token en **Account settings → Security → API tokens → Create API token**.
  4. ```bash
     export JIRA_API_TOKEN="tu-api-token"
     ```
  5. Verificar las variables sin imprimir sus valores:

     ```bash
     test -n "$JIRA_BASE_URL" && echo "JIRA_BASE_URL configurada"
     test -n "$JIRA_EMAIL" && echo "JIRA_EMAIL configurada"
     test -n "$JIRA_API_TOKEN" && echo "JIRA_API_TOKEN configurada"
     ```

- Pedir exactamente: **“Confírmame cuando hayas configurado los accesos.”**
- Después de la confirmación, ejecutar el script una sola vez con los mismos archivos.
- Si vuelve a fallar por autenticación, detenerse e informar que las credenciales siguen sin ser válidas.
- Nunca mostrar, solicitar en el chat ni registrar el valor de `JIRA_API_TOKEN`.

## Otros errores

- Exit code `3`: informar que no se encontró el ticket o proyecto, o que no hay un tipo de subtarea disponible.
- Exit code `4`: informar el error de conexión o respuesta de Jira sin exponer secretos.
- Exit code `5`: informar que faltan `curl` o `jq`.
- Exit code `6`: informar que título o descripción están vacíos, que Jira rechazó el payload, que el parent no puede tener subtareas o que hay varios tipos disponibles y falta elegir uno.
- No afirmar que el ticket fue creado si el script no devuelve un `issue_key`.

## Contrato de salida

El script devuelve JSON con esta forma:

```json
{
  "issue_key": "DTCZE-14436",
  "issue_id": "123456",
  "parent": "DTCZE-12424",
  "project": "DTCZE",
  "issue_type": "Technical Task",
  "title": "Título de la tarea",
  "url": "https://ab-inbev.atlassian.net/browse/DTCZE-14436"
}
```

Para una subtarea, `parent`, `project` e `issue_type` reflejan la configuración resuelta con los datos del parent y la metadata de Jira; el `parent` puede ser distinto de `DTCZE-12424`. `issue_key` e `issue_id` provienen de la respuesta de Jira. Este skill crea tickets en Jira después de la confirmación y no modifica el repositorio.
