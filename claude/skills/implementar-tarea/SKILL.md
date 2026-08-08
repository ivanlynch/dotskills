---
name: implementar-tarea
description: Implementa una única tarea READY de un archivo generado por /plan, respeta sus dependencias y devuelve DONE con evidencia o BLOCKED sin marcar manualmente el archivo como completado.
---

# Implementar Tarea

Implementar exactamente una tarea del archivo ejecutable del plan. No ampliar el alcance, no ejecutar otra tarea y no modificar el archivo manualmente.

## Entrada

```text
/implementar-tarea /ruta/al/PROJ-1234-plan.json --task-id task-001
```

Validar y comenzar la tarea mediante el script común:

```bash
python3 <plan-skill-dir>/scripts/plan_file.py validate "/ruta/al/plan.json"
python3 <plan-skill-dir>/scripts/plan_file.py start \
  "/ruta/al/plan.json" \
  --task-id "<TASK_ID>"
```

El script verifica que la tarea esté `PENDING`, que sus dependencias estén `DONE` y que no exista otra tarea `IN_PROGRESS`.

## Implementación

1. Leer únicamente la tarea seleccionada: título, descripción, pasos, verificaciones, dependencias y restricciones.
2. Buscar y obedecer las instrucciones del proyecto.
3. Inspeccionar el código necesario y ejecutar los pasos de implementación en orden.
4. Mantener los cambios dentro del alcance de esa tarea.
5. Ejecutar las verificaciones indicadas y las validaciones obligatorias del proyecto.
6. Revisar el diff de la tarea sin descartar cambios ajenos.

## Resultado

Si la tarea terminó correctamente, devolver:

```json
{
  "status": "DONE",
  "task_id": "task-001",
  "evidence": "Implementación realizada y verificación ejecutada con resultado PASS."
}
```

No ejecutar `plan_file.py complete`; `/implementar-plan` lo hará después de validar el resultado.

Si no puede terminarse, devolver:

```json
{
  "status": "BLOCKED",
  "task_id": "task-001",
  "reason": "Descripción precisa del bloqueo y decisión necesaria."
}
```

No declarar `DONE` si una verificación falla, falta información esencial o se necesita ampliar el alcance.
