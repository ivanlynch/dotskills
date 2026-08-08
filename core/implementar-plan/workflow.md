---
name: implementar-plan
description: Lee un archivo de plan de implementación, ejecuta sus tareas ordenadas mediante $implementar-tarea y marca cada tarea como DONE en el mismo archivo únicamente después de recibir un resultado DONE con evidencia.
---

# Implementar Plan

Orquestar la ejecución de un archivo generado por `$plan`. No editar el JSON manualmente y no saltar tareas ni dependencias.

## Entrada

Recibir la ruta absoluta del archivo ejecutable del plan:

```text
$implementar-plan /ruta/al/PROJ-1234-plan.json
```

Validarlo antes de cualquier cambio:

```bash
python3 <plan-skill-dir>/scripts/plan_file.py validate "/ruta/al/plan.json"
```

## Flujo

Repetir hasta recibir `PLAN_COMPLETE`:

1. Ejecutar `next` para obtener la siguiente tarea cuyas dependencias estén `DONE`.
2. Si la salida es `BLOCKED`, detenerse y esperar una decisión; no saltar la tarea.
3. Si la salida es `WAIT_DEPENDENCY`, detenerse porque el plan es inconsistente.
4. Si la salida es `IMPLEMENT_TASK`, invocar `$implementar-tarea` con el archivo y el `task.id` devuelto.
5. Esperar el resultado de `$implementar-tarea`.
6. Solo si devuelve `status = DONE` y evidencia no vacía, ejecutar:

   ```bash
   python3 <plan-skill-dir>/scripts/plan_file.py complete \
     "/ruta/al/plan.json" \
     --task-id "<TASK_ID>" \
     --evidence "<evidencia devuelta por implementar-tarea>"
   ```

7. Si devuelve `BLOCKED`, ejecutar `block` con el motivo y detenerse.
8. Ejecutar `validate` después de cada transición.
9. Continuar desde `next`; nunca asumir la siguiente tarea leyendo el archivo directamente.

## Salidas

- `PLAN_COMPLETE`: todas las tareas están `DONE` y el archivo fue actualizado.
- `IMPLEMENT_TASK`: se debe ejecutar `$implementar-tarea`.
- `BLOCKED`: la ejecución requiere una decisión o intervención.
- `WAIT_DEPENDENCY`: el plan es inconsistente o no tiene una tarea ejecutable.

Informar al final la ruta del archivo y el resumen de tareas completadas. El archivo actualizado es la fuente de verdad para continuar posteriormente.
