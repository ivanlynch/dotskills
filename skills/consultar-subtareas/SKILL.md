---
name: consultar-subtareas
description: Consulta en Jira la lista de subtareas de un issue padre y devuelve sus identificadores y títulos en JSON. Usar cuando el usuario proporcione un ticket-id de Jira y necesite conocer, enumerar o cargar el contexto de sus subtareas.
---

# Consultar subtareas de Jira

Ejecutar el flujo con un único `ticket-id` del issue padre.

## Flujo

1. Validar que el argumento tenga formato `^[A-Z][A-Z0-9]+-[0-9]+$` y normalizarlo a mayúsculas.
2. Ejecutar el script de esta skill:

   ```bash
   bash <skill-dir>/scripts/get_subtasks.sh <TICKET_ID>
   ```

3. El script consulta el issue padre mediante la API REST de Jira y devuelve JSON con este formato:

   ```json
   {
     "ticket_id": "DTCZE-1234",
     "subtasks": [
       {
         "ticket_id": "DTCZE-1235",
         "title": "Implementar la validación"
       }
     ]
   }
   ```

   Si el issue no tiene subtareas, `subtasks` debe ser `[]`.

4. Usar los datos devueltos por el script como fuente de verdad. No inventar, completar ni reinterpretar subtareas ausentes.

## Autenticación ausente o inválida

El script utiliza exit code `2` cuando faltan credenciales o Jira responde `401`/`403`. En ese caso:

- Detener inmediatamente la ejecución del comando actual.
- No reintentar automáticamente.
- Explicar al usuario estos pasos, en este orden:

  1. Exportar la base URL de Jira:

     ```bash
     export JIRA_BASE_URL="https://ab-inbev.atlassian.net"
     ```

  2. Exportar el email corporativo:

     ```bash
     export JIRA_EMAIL="tu-email@ab-inbev.com"
     ```

  3. Crear un API token en Atlassian, si todavía no existe:
     - Entrar en el perfil de Atlassian.
     - Abrir **Account settings → Security → API tokens**.
     - Seleccionar **Create API token**.
     - Copiar el token inmediatamente; Atlassian no lo vuelve a mostrar.

  4. Exportar el token en la terminal:

     ```bash
     export JIRA_API_TOKEN="tu-api-token"
     ```

  5. Verificar que las variables estén definidas sin imprimir sus valores:

     ```bash
     test -n "$JIRA_BASE_URL" && echo "JIRA_BASE_URL configurada"
     test -n "$JIRA_EMAIL" && echo "JIRA_EMAIL configurada"
     test -n "$JIRA_API_TOKEN" && echo "JIRA_API_TOKEN configurada"
     ```

- Pedir exactamente una confirmación breve, por ejemplo: **“Confírmame cuando hayas configurado los accesos.”**
- Esperar la confirmación del usuario. No continuar en el mismo turno.
- Después de la confirmación, ejecutar el script una sola vez con el mismo `ticket-id`.
- Si vuelve a fallar por autenticación, detenerse y explicar que las credenciales siguen sin ser válidas; no entrar en un bucle de reintentos.
- Nunca mostrar, registrar, solicitar que se pegue en el chat o incluir en una respuesta el valor de `JIRA_API_TOKEN`.

## Otros errores

- Exit code `3`: informar que el issue padre no fue encontrado.
- Exit code `4`: informar el error de conexión o respuesta de Jira sin exponer secretos.
- Exit code `5`: informar que el entorno no tiene `curl` o `jq` instalados.
- En todos los casos, detenerse sin inventar la lista de subtareas.

## Resultado

Al finalizar correctamente, responder de forma breve con el JSON devuelto por el script. No modificar repositorios ni crear, actualizar o eliminar issues; esta skill solo consulta Jira y está diseñada para ser invocada por otras skills.

