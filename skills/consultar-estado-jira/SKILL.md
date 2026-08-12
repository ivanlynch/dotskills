---
name: consultar-estado-jira
description: Consulta en Jira el estado actual de una lista de issues y devuelve sus identificadores, estados, enlaces y errores individuales en JSON. Usar cuando el usuario proporcione varios tickets Jira como DTCZE-14448, DTCZE-14446 o DTCZE-14449 y necesite saber en qué estado está cada uno.
---

# Consultar estado de issues Jira

Ejecutar el flujo con una lista de identificadores Jira. La lista puede recibirse como argumentos del script o como una línea por ticket mediante stdin.

## Flujo

1. Extraer los identificadores proporcionados por el usuario. Aceptar el formato `PROJECT-123`, sin distinguir mayúsculas y minúsculas.
2. Ejecutar el script de esta skill:

   ```bash
   bash <skill-dir>/scripts/get_issue_statuses.sh DTCZE-14448 DTCZE-14446 DTCZE-14449
   ```

   Para una lista multilinea, usar:

   ```bash
   printf '%s\n' DTCZE-14448 DTCZE-14446 DTCZE-14449 | \
     bash <skill-dir>/scripts/get_issue_statuses.sh
   ```

3. Usar el JSON devuelto por el script como fuente de verdad. Mantener el orden de entrada y no inventar estados.
4. Presentar al usuario una tabla breve con `ticket_id`, `status` y `url`. Para un issue con `error`, mostrar el error en lugar del estado.

## Formato de salida

Una ejecución exitosa devuelve un objeto como este:

```json
{
  "issues": [
    {
      "ticket_id": "DTCZE-14448",
      "status": "In Progress",
      "url": "https://ab-inbev.atlassian.net/browse/DTCZE-14448"
    },
    {
      "ticket_id": "DTCZE-14446",
      "status": "Done",
      "url": "https://ab-inbev.atlassian.net/browse/DTCZE-14446"
    },
    {
      "ticket_id": "DTCZE-14449",
      "status": null,
      "error": "No encontrado",
      "url": "https://ab-inbev.atlassian.net/browse/DTCZE-14449"
    }
  ]
}
```

El `status` es el nombre de estado devuelto por Jira; no traducirlo ni inferirlo. El script preserva los duplicados si el usuario repite un identificador.

## Autenticación ausente o inválida

El script utiliza exit code `2` cuando faltan credenciales o Jira responde `401`/`403`. En ese caso:

- Detener inmediatamente la ejecución.
- No reintentar automáticamente.
- Explicar al usuario estos pasos, en este orden:

  1. Exportar la base URL:

     ```bash
     export JIRA_BASE_URL="https://ab-inbev.atlassian.net"
     ```

  2. Exportar el email corporativo:

     ```bash
     export JIRA_EMAIL="tu-email@ab-inbev.com"
     ```

  3. Crear un API token en Atlassian desde **Account settings → Security → API tokens → Create API token**.
  4. Exportar el token en la terminal:

     ```bash
     export JIRA_API_TOKEN="tu-api-token"
     ```

  5. Verificar las variables sin imprimir sus valores:

     ```bash
     test -n "$JIRA_BASE_URL" && echo "JIRA_BASE_URL configurada"
     test -n "$JIRA_EMAIL" && echo "JIRA_EMAIL configurada"
     test -n "$JIRA_API_TOKEN" && echo "JIRA_API_TOKEN configurada"
     ```

- Pedir exactamente una confirmación breve: **“Confírmame cuando hayas configurado los accesos.”**
- Tras la confirmación, ejecutar el script una sola vez con la misma lista.
- Si vuelve a fallar por autenticación, detenerse e informar que las credenciales siguen sin ser válidas.
- Nunca mostrar, registrar, solicitar en el chat ni incluir en una respuesta el valor de `JIRA_API_TOKEN`.

## Otros errores

- Exit code `1`: uso inválido, lista vacía o identificador con formato incorrecto.
- Exit code `3`: fallo de conexión o respuesta inesperada de Jira.
- Exit code `5`: falta `curl` o `jq`.
- Un issue individual con HTTP `404` no aborta la consulta: aparece en `issues` con `status: null` y `error: "No encontrado"`.
- Si Jira devuelve una respuesta sin `fields.status.name`, informar respuesta inválida y detenerse con exit code `3`.

Esta skill solo consulta Jira; no crea, modifica, transiciona ni elimina issues.
