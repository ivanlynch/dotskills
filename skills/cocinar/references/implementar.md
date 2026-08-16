# Referencia: ejecutar el plan, tarea por tarea

Orquesta la ejecución del archivo generado por la fase `plan`. No editar el archivo manualmente y no saltar tareas ni dependencias.

## Entrada

Recibir la ruta absoluta del archivo ejecutable del plan y `--commit-each` (siempre activo desde `/cocinar`):

```text
<skill-dir>/scripts/plan_file.sh validate "/ruta/al/plan.txt"
```

## Flujo de orquestación

Repetir hasta recibir `PLAN_COMPLETE`:

1. Ejecutar `next` para obtener la siguiente tarea cuyas dependencias estén `DONE`.
2. Si la salida es `BLOCKED`, detenerse y esperar una decisión; no saltar la tarea.
3. Si la salida es `WAIT_DEPENDENCY`, detenerse porque el plan es inconsistente.
4. Si la salida es `IMPLEMENT_TASK`, ejecutar la tarea siguiendo "Implementación de una tarea" más abajo, con el archivo y el `task_id` devuelto.
5. Solo si esa implementación termina en `DONE` con evidencia no vacía, ejecutar:

   ```bash
   <skill-dir>/scripts/plan_file.sh complete \
     "/ruta/al/plan.txt" \
     --task-id "<TASK_ID>" \
     --evidence "<evidencia obtenida>"
   ```

6. Si termina en `BLOCKED`, ejecutar `block` con el motivo y detenerse. Continuar por `/entrevistar` para investigar y agotar alternativas antes de aceptar una limitación o registrar deuda técnica.
7. Ejecutar `validate` después de cada transición.
8. Después de completar la tarea:
   - revisar el diff y confirmar que solo contiene la etapa actual;
   - confirmar que los tests pasan y que se ejecutó coverage si el proyecto lo soporta;
   - crear un commit pequeño con mensaje Conventional Commit en inglés;
   - verificar que el commit se creó antes de continuar.
9. Continuar desde `next`; nunca asumir la siguiente tarea leyendo el archivo directamente.

### Salidas de la orquestación

- `PLAN_COMPLETE`: todas las tareas están `DONE` y el archivo fue actualizado.
- `BLOCKED`: la ejecución requiere una decisión o intervención.
- `WAIT_DEPENDENCY`: el plan es inconsistente o no tiene una tarea ejecutable.
- Un fallo al crear o verificar el commit bloquea la ejecución antes de iniciar otra tarea.

Informar al final la ruta del archivo y el resumen de tareas completadas. El archivo actualizado es la fuente de verdad para continuar posteriormente.

## Implementación de una tarea

Implementar exactamente una tarea del archivo ejecutable del plan. No ampliar el alcance, no ejecutar otra tarea y no modificar el archivo manualmente.

Validar y comenzar la tarea mediante el script común:

```bash
<skill-dir>/scripts/plan_file.sh validate "/ruta/al/plan.txt"
<skill-dir>/scripts/plan_file.sh start \
  "/ruta/al/plan.txt" \
  --task-id "<TASK_ID>"
```

El script verifica que la tarea esté `PENDING`, que sus dependencias estén `DONE` y que no exista otra tarea `IN_PROGRESS`.

Pasos:

1. Leer únicamente la tarea seleccionada: título, descripción, pasos, verificaciones, dependencias y restricciones.
2. Buscar y obedecer las instrucciones del proyecto.
3. Inspeccionar el código necesario y ejecutar los pasos de implementación en orden.
4. Mantener los cambios dentro del alcance de esa tarea.
5. Ejecutar las verificaciones indicadas y las validaciones obligatorias del proyecto.
6. Ejecutar la suite de tests relevante y coverage si el proyecto ya tiene una herramienta o comando configurado para ello. Si no existe soporte de coverage, registrar esa limitación en la evidencia sin instalar una herramienta nueva.
7. Revisar el diff de la tarea sin descartar cambios ajenos.

Si una verificación falla o no puede ejecutarse, no dar la tarea por `DONE` ni registrar automáticamente deuda técnica. Investigar las instrucciones y comandos disponibles del proyecto, probar las opciones seguras que correspondan y, si todavía hace falta una decisión o intervención, tratarla como `BLOCKED` para invocar `/entrevistar` y agotar las alternativas con el usuario.

Resultado de esta implementación puntual (antes de volver al paso 5 de la orquestación):

- `DONE` con evidencia: verificación ejecutada y resultado obtenido.
- `BLOCKED` con motivo: descripción precisa del bloqueo y decisión necesaria.

No declarar `DONE` si una verificación falla, falta información esencial o se necesita ampliar el alcance. No ejecutar `plan_file.sh complete` desde acá: la orquestación lo hace después de validar el resultado.
