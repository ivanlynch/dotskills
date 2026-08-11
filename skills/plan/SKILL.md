---
name: plan
description: Genera un plan completo de implementación a partir de un alcance confirmado y persiste cada incremento como una tarea ejecutable con validaciones. Usar en modo normal cuando el usuario necesite convertir incrementos en tickets mediante /crear-ticket, o en modo interno cuando /cocinar necesite planificar etapas sin crear tickets.
---

# Plan

Convertir un alcance confirmado por `/analizar-alcance` en un plan de implementación ejecutable. No implementar código, no crear branches y no abrir pull requests. El modo normal crea tickets; el modo `--internal`, reservado para `/cocinar`, persiste etapas internas sin crear tickets de Jira.

## Modos

- Sin `--internal`: invocar `/crear-ticket` para cada tarea, como flujo de planificación independiente.
- Con `--internal`: redactar directamente títulos y descripciones breves para las etapas, sin invocar `/crear-ticket` ni pedir confirmación por cada etapa.

## Contrato de entrada

No recibís el alcance como texto: `<skill-dir>/scripts/plan_state.sh init <TICKET_ID>` lee directamente el registro que dejó `/analizar-alcance` para ese mismo ticket y proyecto (texto plano, sin JSON, sin Python — ver `<analizar-alcance-skill-dir>/scripts/workflow_state.sh`). El script rechaza el `init` si el alcance de ese ticket no está `CONFIRMED`, si falta el objetivo, o si no hay ningún work item con verdict `APTO_PARA_IMPLEMENTAR`; no hay forma de arrancar con un alcance incompleto o bloqueado.

Nunca edites a mano el archivo de estado que persiste el script.

## Flujo obligatorio

### 1. Inicializar y validar

1. Ejecutar `init <TICKET_ID>`.
2. Ejecutar `validate`.
3. Ejecutar `next` para obtener el siguiente work item pendiente.
4. No analizar manualmente el árbol ni editar el estado directamente.

### 2. Convertir cada work item en una tarea

Para cada work item devuelto por `next`:

1. Definir cómo se implementará: pasos técnicos, orden, archivos o módulos candidatos solo cuando estén respaldados por la guía del proyecto, verificaciones y dependencias.
2. En modo normal, invocar `/crear-ticket` para generar el título y la descripción de la tarea. Pasar como contexto el work item, el alcance global, las decisiones confirmadas y el plan técnico descubierto.
3. En modo `--internal`, redactar directamente un título y una descripción orientados al resultado, junto con sus pasos y verificaciones. No invocar `/crear-ticket`.
4. En modo normal, respetar la salida de `/crear-ticket` y esperar su confirmación; en modo `--internal`, no esperar confirmación por etapa porque `/cocinar` ya la obtuvo antes de implementar.
5. Persistir inmediatamente la tarea con una sola operación:

   ```bash
   <skill-dir>/scripts/plan_state.sh task-add <TICKET_ID> \
     --source-node-id <NODE_ID> \
     --title "<título pt-BR>" \
     --description "<descripción pt-BR>" \
     --implementation-step "<paso técnico>" \
     --verification "<verificación>" \
     [--depends-on <TASK_ID>]
   ```

6. Ejecutar `validate` después de cada tarea.
7. Si un work item necesita varias tareas, repetir el paso de generación correspondiente al modo activo y `task-add` para cada una antes de cerrarlo.
8. Marcar el work item completo con:

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

   Este archivo (texto plano, sin JSON) es la única entrada de `/implementar-plan`. No modificarlo manualmente.

4. Obtener la salida final consumible por `aprobacion` o `implementacion`:

   ```bash
   <skill-dir>/scripts/plan_state.sh export <TICKET_ID>
   ```

La salida final debe informar el objetivo, la lista de tareas en orden y la ruta del archivo ejecutable creado en el paso 3. No entregar el estado interno del script como sustituto del plan.

## Reglas de decisión

- Una tarea del plan debe tener un único resultado observable y una verificación concreta.
- Mantener las tareas pequeñas y ordenadas por dependencia.
- En modo normal, no crear tareas técnicas sin título y descripción generados por `/crear-ticket`. En modo `--internal`, el propio plan debe generar esos campos de forma breve y verificable.
- No inventar archivos, endpoints, módulos, APIs ni comandos.
- Separar alcance incluido, fuera de alcance, supuestos, riesgos, verificaciones y deuda técnica.
- Si falta una decisión de producto o comportamiento, detener el work item e invocar `/entrevistar`; no asumir silenciosamente. Solo el modo normal puede usar `/crear-ticket` para convertir una tarea ya definida en un issue.
- Si el script devuelve `ERROR: ...` (exit distinto de 0), corregir lo que indique el mensaje y no editar el estado manualmente.
- Si una tarea queda bloqueada, usar `/entrevistar` para cerrar la decisión y luego ejecutar `task-unblock` con la resolución antes de continuar.

## Resultado final

Entregar solamente un resumen breve y la salida de `plan_state.sh export`, indicando:

- `PLAN_COMPLETE` o el bloqueo actual;
- cantidad de tareas listas;
- dependencias o riesgos relevantes;
- ruta del registro persistido.
