---
name: consultar-ticket
description: Consultar el título y la descripción de un ticket de Jira mediante un script REST reutilizable. Usar cuando el usuario proporcione un ticket-id, por ejemplo `$consultar-ticket DTCZE-1234`, o cuando otro comando necesite cargar el contexto de una tarea Jira.
---

# Consultar Jira

Ejecutar el flujo con un único `ticket-id`.

## Flujo

1. Validar que el argumento tenga formato `^[A-Z][A-Z0-9]+-[0-9]+$` y normalizarlo a mayúsculas.
2. Ejecutar el script de esta skill:

   ```bash
   python3 <skill-dir>/scripts/get_ticket.py <TICKET_ID>
   ```

3. El script debe devolver JSON con exactamente estos datos del ticket:

   ```json
   {
     "ticket_id": "DTCZE-1234",
     "title": "Título del ticket",
     "description": "Descripción del ticket"
   }
   ```

4. Usar el título y la descripción devueltos por el script como fuente de verdad para el comando que invocó esta skill. No inventar, completar ni reinterpretar datos ausentes.

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

- Exit code `3`: informar que el ticket no fue encontrado.
- Exit code `4`: informar el error de conexión o respuesta de Jira sin exponer secretos.
- En ambos casos, detenerse sin inventar el título ni la descripción.

## Resultado

Al finalizar correctamente, responder de forma breve:

```text
Ticket: <ticket_id>
Título: <title>
Descripción:
<description>
```

No modificar repositorios ni crear o actualizar tickets. Esta skill solo consulta Jira y está diseñada para ser invocada por otras skills, como `crear-feature-flag`.
