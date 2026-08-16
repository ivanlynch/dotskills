# Referencia: producir el plan interno de etapas

Convierte el alcance confirmado por la fase `analizar-alcance` en un plan de implementación ejecutable. No implementar código, no crear branches y no abrir pull requests. Uso exclusivo de `/cocinar` — persiste etapas internas sin crear tickets de Jira, no invoca `/crear-ticket`.

## Contrato de entrada

No se recibe el alcance como texto: `<skill-dir>/scripts/plan_state.sh init <TICKET_ID>` lee directamente el registro que dejó la fase `analizar-alcance` para ese mismo ticket y proyecto (texto plano, sin JSON, sin Python — ver `<skill-dir>/scripts/workflow_state.sh`). El script rechaza el `init` si el alcance de ese ticket no está `CONFIRMED`, si falta el objetivo, o si no hay ningún work item con verdict `APTO_PARA_IMPLEMENTAR`; no hay forma de arrancar con un alcance incompleto o bloqueado.

Nunca editar a mano el archivo de estado que persiste el script.

## Flujo obligatorio

### 1. Inicializar y validar

1. Ejecutar `init <TICKET_ID>`.
2. Ejecutar `validate`.
3. Ejecutar `next` para obtener el siguiente work item pendiente.
4. No analizar manualmente el árbol ni editar el estado directamente.

### 2. Convertir cada work item en una tarea

Para cada work item devuelto por `next`:

1. Definir cómo se implementará: pasos técnicos, orden, archivos o módulos candidatos solo cuando estén respaldados por la guía del proyecto, verificaciones y dependencias.
2. Redactar directamente un título y una descripción orientados al resultado, junto con sus pasos y verificaciones. No esperar confirmación por etapa — `/cocinar` ya obtuvo la aprobación del alcance antes de llegar acá.
3. Persistir inmediatamente la tarea con una sola operación:

   ```bash
   <skill-dir>/scripts/plan_state.sh task-add <TICKET_ID> \
     --source-node-id <NODE_ID> \
     --title "<título pt-BR>" \
     --description "<descripción pt-BR>" \
     --implementation-step "<paso técnico>" \
     --verification "<verificación>" \
     [--depends-on <TASK_ID>]
   ```

4. Ejecutar `validate` después de cada tarea.
5. Si un work item necesita varias tareas, repetir la redacción y `task-add` para cada una antes de cerrarlo.
6. Marcar el work item completo con:

   ```bash
   <skill-dir>/scripts/plan_state.sh item-complete <TICKET_ID> --source-node-id <NODE_ID>
   ```

   El script solo lo permite si tiene al menos una tarea `READY` y no tiene tareas bloqueadas.

### 3. Cerrar y exportar el plan

Después de procesar todos los work items:

1. Ejecutar `validate`.
2. Ejecutar:

   ```bash
   <skill-dir>/scripts/plan_state.sh complete <TICKET_ID> --evidence "<resumen breve>"
   ```

3. Crear obligatoriamente el archivo ejecutable del plan:

   ```bash
   <skill-dir>/scripts/plan_state.sh export-file <TICKET_ID> --output "<ruta del plan>.txt"
   ```

   Este archivo (texto plano, sin JSON) es la única entrada de la fase `implementacion`. No modificarlo manualmente.

4. Obtener la salida final consumible por las fases `aprobacion` o `implementacion`:

   ```bash
   <skill-dir>/scripts/plan_state.sh export <TICKET_ID>
   ```

La salida final debe informar el objetivo, la lista de tareas en orden y la ruta del archivo ejecutable creado en el paso 3. No entregar el estado interno del script como sustituto del plan.

## Reglas de decisión

- Una tarea del plan debe tener un único resultado observable y una verificación concreta.
- Mantener las tareas pequeñas y ordenadas por dependencia.
- El propio plan debe generar título y descripción de forma breve y verificable, sin delegar esa redacción a otra skill.
- No inventar archivos, endpoints, módulos, APIs ni comandos.
- Separar alcance incluido, fuera de alcance, supuestos, riesgos, verificaciones y deuda técnica.
- Si falta una decisión de producto o comportamiento, detener el work item e invocar `/entrevistar`; no asumir silenciosamente.
- Si el script devuelve `ERROR: ...` (exit distinto de 0), corregir lo que indique el mensaje y no editar el estado manualmente.
- Si una tarea queda bloqueada, usar `/entrevistar` para cerrar la decisión y luego ejecutar `task-unblock` con la resolución antes de continuar.

## Resultado final

Entregar solamente un resumen breve y la salida de `plan_state.sh export`, indicando:

- `PLAN_COMPLETE` o el bloqueo actual;
- cantidad de tareas listas;
- dependencias o riesgos relevantes;
- ruta del registro persistido.
