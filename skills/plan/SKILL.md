---
name: plan
description: Convierte una spec técnica ya completa en un plan de tareas trazables (changes/<slug>/plan.md), donde cada tarea declara qué escenarios RF00NE00N cubre y de qué otras tareas depende. Úsala cuando haya una spec aprobada y haga falta desglosarla en trabajo ejecutable antes de implementar.
---

# Plan

Traduce una **spec técnica ya aprobada** (`Estado: Completo`, generada por `/spec`) en un **plan de tareas** (`plan.md`): una lista de tareas donde cada una cubre uno o más escenarios `RF00NE00N` y declara sus dependencias, mediante un proceso de entrevista interactivo. No ejecuta ni implementa nada — solo produce el documento, igual que `/idea` y `/spec`.

## Flujo de Trabajo

El documento se completa con comandos, no editando el archivo a mano: cada tarea confirmada en la entrevista se registra de inmediato con `crear_plan.sh`, y al final `check` confirma mecánicamente que todos los escenarios de la spec quedaron cubiertos por alguna tarea. No des el plan por terminado por criterio propio — dejá que `check` lo confirme.

**A diferencia de `/spec`** (una sección scaffoldeada por cada `RF00N`), acá la relación tarea↔escenario es muchos-a-muchos: una tarea puede cubrir varios escenarios, y un escenario puede necesitar varias tareas. Por eso no hay una sección por escenario — es una lista plana de tareas, y la cobertura se verifica releyendo la spec original, no contando placeholders por escenario.

### 1. Ubicar la spec de entrada

Necesitás la ruta de un `spec.md` con `**Estado:** Completo`. Si el usuario nombra la feature en vez de la ruta, infiere `changes/<slug>/spec.md`. Si la spec todavía está en Borrador, no sigas: primero hay que completarla con `/spec`.

### 2. Crear el archivo

```bash
<skill-dir>/scripts/crear_plan.sh init "<ruta_spec>" [ruta_salida]
```

Si omitís `ruta_salida`, el script guarda el plan junto a la spec (`changes/<slug>/plan.md`, mismo directorio que `spec.md`). El script imprime por stdout la lista completa de escenarios `RF00NE00N` de la spec, en orden — esa es la agenda de cobertura que hay que completar, no hace falta que la releas vos mismo de la spec.

Guardá la ruta del plan y la lista de escenarios: las vas a usar en el paso siguiente.

### 3. Entrevistar y registrar tareas

Recorré los escenarios pendientes de cobertura (los que imprimió `init`, y los que `check` siga marcando como faltantes). Para cada tarea:

1. Aplicá `/entrevistar` para definir, con el usuario: qué hace la tarea (título + descripción orientada al resultado), qué escenarios `RF00NE00N` cubre (pueden ser varios, incluso de distintos `RF00N`), de qué otras tareas depende (si depende de alguna, esa tarea ya tiene que existir en el plan) y cuál es su verificación concreta.
2. Cuando el usuario confirme la tarea completa, registrala:
   ```bash
   <skill-dir>/scripts/crear_plan.sh add "<ruta_plan>" --tarea "<título>" "<descripción>" \
     --verificacion "<texto>" [--depende-de <T00N> ...] --cubre <RF00NE00N> [<RF00NE00N> ...]
   ```
   No le asignes vos un ID: el script calcula automáticamente el próximo `T00N`. El script rechaza `--cubre` con un escenario que no existe en la spec y `--depende-de` con una tarea que todavía no existe en el plan — si alguno falla, es señal de un typo o de que falta agregar la tarea dependencia primero.
3. Preguntá explícitamente si hace falta otra tarea (para terminar de cubrir escenarios pendientes, o porque un escenario ya cubierto necesita más de una tarea) — no des la lista por cerrada por tu cuenta.
4. Cuando el usuario confirme que no hace falta ninguna tarea más, cerrá la lista:
   ```bash
   <skill-dir>/scripts/crear_plan.sh add "<ruta_plan>" --tarea --cerrar-lista
   ```

`--cerrar-lista` se puede usar solo o combinado con la última tarea en la misma llamada.

### 4. Verificar completitud mecánica

```bash
<skill-dir>/scripts/crear_plan.sh check "<ruta_plan>"
```

Si reporta escenarios sin cubrir, volvé al paso 3 y agregá la tarea que falte (la lista de tareas hay que reabrirla agregando de nuevo, sin `--cerrar-lista`, salvo que ya esté cerrada — en ese caso agregá la tarea y volvé a cerrar). Si reporta una dependencia inexistente, corregí el `--depende-de` de esa tarea. Repetí hasta que `check` confirme que no queda ningún problema.

### 5. Aprobación del usuario

`check` en OK no alcanza para dar el plan por terminado: la completitud del *contenido* la aprueba el usuario, no el script. Presentale un **resumen objetivo**: cada tarea con su ID, qué escenarios cubre y de qué depende. Esperá su confirmación explícita.

Recién cuando el usuario apruebe, marcá el documento como completo:

```bash
<skill-dir>/scripts/crear_plan.sh aprobar "<ruta_plan>"
```

Si el usuario pide cambios, volvé al paso 3 antes de aprobar.

### 6. Entrega

Mostrale el archivo final al usuario.

## Skills relacionadas

- `/spec`: genera la spec con `Estado: Completo` y los escenarios `RF00NE00N` que esta skill consume como entrada obligatoria.
- `/entrevistar`: conduce cada entrevista del paso 3, una pregunta a la vez con recomendación.
