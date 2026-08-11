---
name: implementar-plan
description: Lee un archivo de plan de implementación, ejecuta sus tareas ordenadas mediante /implementar-tarea y marca cada tarea como DONE después de recibir evidencia. Usar para ejecutar un plan tarea por tarea; con --commit-each, crear además un commit pequeño y verificable después de cada etapa, especialmente desde /cocinar.
---

# Implementar Plan

Orquestar la ejecución de un archivo generado por `/plan`. No editar el archivo manualmente y no saltar tareas ni dependencias.

## Entrada

Recibir la ruta absoluta del archivo ejecutable del plan y, opcionalmente, `--commit-each`:

```text
/implementar-plan /ruta/al/PROJ-1234-plan.txt
/implementar-plan /ruta/al/PROJ-1234-plan.txt --commit-each
```

Validarlo antes de cualquier cambio:

```bash
<plan-skill-dir>/scripts/plan_file.sh validate "/ruta/al/plan.txt"
```

## Flujo

Repetir hasta recibir `PLAN_COMPLETE`:

1. Ejecutar `next` para obtener la siguiente tarea cuyas dependencias estén `DONE`.
2. Si la salida es `BLOCKED`, detenerse y esperar una decisión; no saltar la tarea.
3. Si la salida es `WAIT_DEPENDENCY`, detenerse porque el plan es inconsistente.
4. Si la salida es `IMPLEMENT_TASK`, invocar `/implementar-tarea` con el archivo y el `task_id` devuelto.
5. Esperar el resultado de `/implementar-tarea`.
6. Solo si devuelve `DONE` con evidencia no vacía, ejecutar:

   ```bash
   <plan-skill-dir>/scripts/plan_file.sh complete \
     "/ruta/al/plan.txt" \
     --task-id "<TASK_ID>" \
     --evidence "<evidencia devuelta por implementar-tarea>"
   ```

7. Si devuelve `BLOCKED`, ejecutar `block` con el motivo y detenerse.
8. Ejecutar `validate` después de cada transición.
9. Si se recibió `--commit-each`, después de completar la tarea:
   - revisar el diff y confirmar que solo contiene la etapa actual;
   - confirmar que los tests pasan y que se ejecutó coverage si el proyecto lo soporta;
   - crear un commit pequeño con mensaje Conventional Commit en inglés;
   - verificar que el commit se creó antes de continuar.
10. Continuar desde `next`; nunca asumir la siguiente tarea leyendo el archivo directamente.

## Salidas

- `PLAN_COMPLETE`: todas las tareas están `DONE` y el archivo fue actualizado.
- `IMPLEMENT_TASK`: se debe ejecutar `/implementar-tarea`.
- `BLOCKED`: la ejecución requiere una decisión o intervención.
- `WAIT_DEPENDENCY`: el plan es inconsistente o no tiene una tarea ejecutable.
- Con `--commit-each`, un fallo al crear o verificar el commit bloquea la ejecución antes de iniciar otra tarea.

Informar al final la ruta del archivo y el resumen de tareas completadas. El archivo actualizado es la fuente de verdad para continuar posteriormente.
