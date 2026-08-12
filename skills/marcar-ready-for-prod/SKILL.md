---
name: marcar-ready-for-prod
description: Actualiza el estado de un issue de Jira a Ready for Prod usando la transición disponible en su workflow. Usar cuando el usuario proporcione un ticket-id y pida marcar una tarea, issue o subtarea como lista para producción.
---

# Marcar Ready for Prod

Ejecutar el flujo con un único `ticket-id` de Jira.

El board de trabajo es `54142`. El skill detecta el único sprint activo de ese board y agrega allí el issue antes de cambiar su estado.

## Flujo

1. Validar que el argumento tenga formato `^[A-Z][A-Z0-9]+-[0-9]+$` y normalizarlo a mayúsculas.
2. Ejecutar el script de esta skill:

   ```bash
   bash <skill-dir>/scripts/transition_ready_for_prod.sh <TICKET_ID>
   ```

3. El script consulta el sprint activo del board `54142` mediante Jira Agile API.
4. Si existe un único sprint activo, agregar allí el issue.
5. Consultar las transiciones disponibles del issue y buscar una transición cuyo nombre sea exactamente `Ready for Prod`, ignorando mayúsculas y minúsculas.
6. Si existe una única transición coincidente, ejecutarla mediante la API REST de Jira.
7. No asumir ni inventar IDs de sprint o transición. Si falta el sprint activo, hay más de uno o la transición no está disponible, detenerse y reportar el problema.
8. Usar el JSON devuelto como fuente de verdad. No afirmar que el issue fue asignado o cambió de estado si el script no confirma ambas operaciones.

## Resultado

Una ejecución correcta devuelve:

```json
{
  "ticket_id": "DTCZE-14435",
  "board_id": "54142",
  "sprint_id": "123",
  "sprint_name": "Sprint 42",
  "transition": "Ready for Prod",
  "status": "Ready for Prod"
}
```

No crear, editar ni eliminar otros campos del issue. Esta skill solo ejecuta la transición de estado solicitada.

## Autenticación ausente o inválida

El script utiliza exit code `2` cuando faltan credenciales o Jira responde `401`/`403`. En ese caso:

- Detener inmediatamente la ejecución.
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
- Después de la confirmación, ejecutar el script una sola vez con el mismo `ticket-id`.
- Si vuelve a fallar por autenticación, detenerse e informar que las credenciales siguen sin ser válidas.
- Nunca mostrar, solicitar en el chat ni registrar el valor de `JIRA_API_TOKEN`.

## Otros errores

- Exit code `3`: informar que el issue no fue encontrado.
- Exit code `4`: informar el error de conexión o respuesta de Jira sin exponer secretos.
- Exit code `5`: informar que faltan `curl` o `jq`.
- Exit code `6`: informar que el ID es inválido, que no hay exactamente un sprint activo, que el issue no puede asignarse al sprint, que `Ready for Prod` no está disponible o que la respuesta no permite identificar una única transición.
- No reintentar una transición fallida automáticamente: el estado final podría ser ambiguo.
