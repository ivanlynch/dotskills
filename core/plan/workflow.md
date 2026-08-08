---
name: plan
description: Genera un plan completo de implementación a partir de un alcance confirmado, convierte cada incremento en un ticket mediante $crear-ticket y persiste cada tarea con validaciones. Úsala cuando el usuario quiera planificar cómo implementar una tarea antes de modificar código.
---

# Plan

Convertir un `scope_handoff` confirmado en un plan de implementación ejecutable. No implementar código, no crear branches y no abrir pull requests.

## Contrato de entrada

Recibir exclusivamente el resultado final de `$analizar-alcance` con:

```text
action = ANALYSIS_COMPLETE
next_phase = plan
scope_handoff = alcance confirmado
```

No iniciar si falta el alcance, existe un nodo bloqueado o algún work item no está cerrado.

Inicializar el registro entregando el alcance al script; el agente no debe editar el JSON del estado:

```bash
python3 <skill-dir>/scripts/plan_state.py init <TICKET_ID> --scope-json '<scope_handoff completo>'
```

El script persiste el estado en un archivo temporal asociado al ticket y al proyecto actual.

## Flujo obligatorio

### 1. Inicializar y validar

1. Ejecutar `init` con el `scope_handoff`.
2. Ejecutar `validate`.
3. Ejecutar `next` para obtener el siguiente work item pendiente.
4. No analizar manualmente el árbol ni editar el estado directamente.

### 2. Convertir cada work item en una tarea

Para cada work item devuelto por `next`:

1. Definir cómo se implementará: pasos técnicos, orden, archivos o módulos candidatos solo cuando estén respaldados por la guía del proyecto, verificaciones y dependencias.
2. Invocar `$crear-ticket` para generar el título y la descripción de la tarea. Pasar como contexto el work item, el alcance global, las decisiones confirmadas y el plan técnico descubierto.
3. Respetar la salida de `$crear-ticket`: el título y la descripción final deben estar en portugués de Brasil (`pt-BR`).
4. Esperar la confirmación exigida por `$crear-ticket`; no registrar una tarea preliminar como terminada.
5. Persistir inmediatamente el resultado aprobado con una sola operación:

   ```bash
   python3 <skill-dir>/scripts/plan_state.py task-add <TICKET_ID> \
     --source-node-id <NODE_ID> \
     --title "<título pt-BR>" \
     --description "<descripción pt-BR>" \
     --implementation-step "<paso técnico>" \
     --verification "<verificación>" \
     [--depends-on <TASK_ID>]
   ```

6. Ejecutar `validate` después de cada tarea.
7. Si un work item necesita varias tareas, repetir `$crear-ticket` y `task-add` para cada una antes de cerrarlo.
8. Marcar el work item completo con:

   ```bash
   python3 <skill-dir>/scripts/plan_state.py item-complete <TICKET_ID> --source-node-id <NODE_ID>
   ```

   El script solo lo permite si tiene al menos una tarea `READY` y no tiene tareas bloqueadas.

### 3. Cerrar y exportar el plan

Después de procesar todos los work items:

1. Ejecutar `validate`.
2. Ejecutar:

   ```bash
   python3 <skill-dir>/scripts/plan_state.py complete <TICKET_ID> --evidence "<resumen breve>"
   ```

3. Crear obligatoriamente el archivo ejecutable del plan:

   ```bash
   python3 <skill-dir>/scripts/plan_state.py export-file <TICKET_ID> --output "<ruta del plan>.json"
   ```

   Este archivo es la única entrada de `$implementar-plan`. No modificarlo manualmente.

4. Obtener la salida final consumible por `aprobacion` o `implementacion`:

   ```bash
   python3 <skill-dir>/scripts/plan_state.py export <TICKET_ID>
   ```

La salida final debe tener `action = PLAN_COMPLETE`, contener el objetivo, el alcance, las tareas en orden, dependencias, verificaciones, riesgos y deuda técnica, e informar la ruta del archivo ejecutable. No entregar el JSON interno del estado como sustituto del plan.

## Reglas de decisión

- Una tarea del plan debe tener un único resultado observable y una verificación concreta.
- Mantener las tareas pequeñas y ordenadas por dependencia.
- No crear tareas técnicas sin título y descripción generados por `$crear-ticket`.
- No inventar archivos, endpoints, módulos, APIs ni comandos.
- Separar alcance incluido, fuera de alcance, supuestos, riesgos, verificaciones y deuda técnica.
- Si falta una decisión de producto o comportamiento, detener el work item e invocar `$crear-ticket`/`$entrevistar` según corresponda; no asumir silenciosamente.
- Si el script devuelve `ok: false`, corregir la operación indicada y no editar el estado manualmente.
- Si una tarea queda bloqueada, usar `$entrevistar` para cerrar la decisión y luego ejecutar `task-unblock` con la resolución antes de continuar.

## Resultado final

Entregar solamente un resumen breve y la salida de `plan_state.py export`, indicando:

- `PLAN_COMPLETE` o el bloqueo actual;
- cantidad de tareas listas;
- dependencias o riesgos relevantes;
- ruta del registro persistido.
