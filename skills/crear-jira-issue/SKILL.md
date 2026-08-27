---
name: crear-jira-issue
description: Entrevista al usuario, genera el título y la descripción de una tarea en portugués de Brasil y crea un Technical Task independiente en DTCZE mediante la API REST de Jira. Usar cuando el usuario necesite definir y registrar una tarea nueva, especialmente en el proyecto DTCZE o en el board 54142.
---

# Crear Jira issue

Este skill combina el flujo de `/crear-ticket` con la creación efectiva del issue en Jira. La entrevista y la confirmación son obligatorias antes de realizar la escritura.

## Configuración fija

- Proyecto Jira: `DTCZE`.
- Parent: `DTCZE-12424` (Epic de DTC Zé Courier - BAU).
- Tipo criado: `Technical Task` (`id: 11737`).
- Board de referencia: `https://ab-inbev.atlassian.net/jira/software/c/projects/DTCZE/boards/54142/backlog`.
- Sprint fijo de creación: `Backlog Priorizado` (`customfield_10007`, sprint ID `114686`, board `54142`).
- Team Name fijo de creación: `ZE_Last_Mile` (`customfield_13230`, opción ID `61436`).

No usar el board para crear el issue. La API REST crea el proyecto, tipo, parent y Team Name; después de crear el issue, la API Agile lo agrega al sprint.
El script debe asignar explícitamente `parent`, `Team Name` y `Backlog Priorizado`; no depender de valores predeterminados o automatizaciones de Jira.

## Flujo de entrevista

Usar `/entrevistar` como parte obligatoria del flujo:

1. Hacer una sola pregunta por turno.
2. Mantener cada pregunta breve y directa.
3. Incluir una recomendación concreta después de cada pregunta.
4. Esperar la respuesta antes de continuar.
5. Investigar hechos disponibles en el workspace en lugar de preguntarlos.
6. Plantear al usuario las decisiones, preferencias y supuestos que no puedan descubrirse.
7. No generar ni crear el issue final hasta alcanzar un entendimiento compartido y recibir confirmación explícita.

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

Antes de crear el issue, presentar en español el entendimiento compartido y pedir confirmación explícita. Después de la confirmación, generar título y descripción naturales en portugués de Brasil (`pt-BR`) con este formato:

```markdown
## Título

[Módulo/Componente]: Breve descrição do objetivo

## Contexto ou declaração do problema

[Razão de negócio ou problema técnico.]

## Descrição / User Story

**Como** [papel do usuário / sistema],
**quero** [ação ou funcionalidade],
**para** [benefício ou objetivo].

## Critérios de aceitação

- **Dado que** [pré-condição], **quando** [ação], **então** [resultado verificável].
- [ ] [Critério adicional verificável]

## Detalhes técnicos e considerações

- **Endpoints / APIs envolvidas:** [detalhe ou Não se aplica]
- **Módulos / domínio:** [detalhe ou Não se aplica]
- **Dependências e restrições:** [detalhe ou Não se aplica]

## Design / recursos

- **Figma:** [link ou Não se aplica]
- **Documentação / RFC:** [link ou Não se aplica]
- **Outros recursos:** [link, captura, log ou Não se aplica]
```

Para um bug, adaptar la estructura para incluir reproducibilidad, comportamiento esperado, comportamiento actual y evidencia, manteniendo la salida en `pt-BR`.

## Crear el issue

1. Guardar el título final y la descripción final aprobados en archivos temporales, sin incluir secretos. Mantener la descripción en Markdown siguiendo la plantilla; el script la convierte a Atlassian Document Format (ADF) antes de enviarla a Jira. No convertirla manualmente a JSON ni enviarla como texto plano.
2. Ejecutar una sola vez el script de esta skill:

   ```bash
   bash <skill-dir>/scripts/create_jira_issue.sh \
     --title-file "/ruta/al/titulo.txt" \
     --description-file "/ruta/a/la/descripcion.md"
   ```

3. El script crea um `Technical Task` com parent `DTCZE-12424`, `Team Name = ZE_Last_Mile` e o associa ao sprint `Backlog Priorizado` em uma segunda chamada à API Agile.
4. No reintentar automáticamente una creación fallida: una repetición podría duplicar el issue. Si la respuesta es ambigua, consultar Jira antes de volver a crear.
5. Informar el JSON devuelto por el script y el enlace al issue creado.

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

- Exit code `3`: informar que el proyecto DTCZE o el issue type `Technical Task` no fue encontrado o no puede usarse.
- Exit code `4`: informar el error de conexión o respuesta de Jira sin exponer secretos.
- Exit code `5`: informar que faltan `curl` o `jq`.
- Exit code `6`: informar que título o descripción están vacíos o que Jira rechazó el payload.
- No afirmar que el issue fue creado si el script no devuelve un `issue_key`.

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

Este skill crea issues en Jira después de confirmación; no modifica el repositorio ni crea tickets adicionales fuera del issue solicitado.
