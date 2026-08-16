---
name: spec
description: Traduce un PRD ya completo en una especificación técnica (changes/<slug>/spec.md) con un escenario Gherkin (Dado/Cuando/Entonces) por cada requerimiento RF00N. Úsala cuando haya un PRD aprobado y haga falta definir el contrato de comportamiento técnico antes de diseñar o implementar.
---

# Spec

Traduce un **PRD ya aprobado** (`Estado: Completo`, generado por `/idea`) en una **especificación técnica** (`spec.md`): un escenario Gherkin (Dado/Cuando/Entonces) por cada requerimiento `RF00N`, mediante un proceso de entrevista interactivo.

## Flujo de Trabajo

El documento se completa con comandos, no editando el archivo a mano: cada escenario confirmado en la entrevista se registra de inmediato con `crear_spec.sh`, y al final `check` confirma mecánicamente que ninguna sección quedó sin escenario. No des el spec por terminado por criterio propio — dejá que `check` lo confirme.

**A diferencia de `/idea`, acá el vocabulario técnico está permitido y esperado**: estados, códigos de respuesta, eventos, validaciones. Lo que sigue sin corresponder a esta etapa es el *diseño* técnico (esquemas de datos, endpoints concretos, decisiones de arquitectura) — eso es una etapa futura (`/design`), no ésta. No inventes decisiones de diseño no confirmadas por el usuario; si aparece una durante la entrevista, usá `/entrevistar` para cerrarla como decisión, no la asumas.

### 1. Ubicar el PRD de entrada

Necesitás la ruta de un `prd.md` con `**Estado:** Completo`. Si el usuario nombra la feature en vez de la ruta, infiere `changes/<slug>/prd.md`. Si el PRD todavía está en Borrador, no sigas: primero hay que completarlo con `/idea`.

### 2. Crear el archivo

```bash
<skill-dir>/scripts/crear_spec.sh init "<ruta_prd>" [ruta_salida]
```

Si omitís `ruta_salida`, el script guarda el spec junto al PRD (`changes/<slug>/spec.md`, mismo directorio que `prd.md`). El script lee el PRD, extrae su título y cada requerimiento `#### RF00N: <título>`, y genera **una sección por cada uno**, cada una con su propio placeholder de lista. No hace falta que vos re-derives la lista de requerimientos del PRD: el script la imprime por stdout, en orden — esa es la agenda de la entrevista.

Guardá la ruta del spec y la lista de RF-IDs impresa: las vas a usar en el paso siguiente.

### 3. Entrevistar y registrar, por cada RF-ID

Para cada `RF00N` (en el orden que imprimió `init`):

1. Aplicá `/entrevistar` para definir el **escenario feliz** de ese requerimiento, en formato Gherkin y en español:
   ```
   Dado <precondición>
   Cuando <acción>
   Entonces <resultado>
   ```
   Podés encadenar pasos adicionales con `Y`. Cuando el usuario confirme el escenario completo, registralo (no le asignes vos un ID: el script calcula automáticamente el próximo `RF00NE00N` dentro de esa sección, igual que asigna `RF00N` en `/idea`):
   ```bash
   <skill-dir>/scripts/crear_spec.sh add "<ruta_spec>" --escenario <RF-ID> "<nombre del escenario>" "<bloque Gherkin>"
   ```
2. Preguntá explícitamente si hay casos borde, de error o de permisos para ese mismo requerimiento — no des la lista por cerrada por tu cuenta. Por cada uno que el usuario confirme, otro `add --escenario` con el mismo `<RF-ID>`.
3. Cuando el usuario confirme que no hay más escenarios para ese RF, cerrá la sección:
   ```bash
   <skill-dir>/scripts/crear_spec.sh add "<ruta_spec>" --escenario <RF-ID> --cerrar-lista
   ```
4. Pasá al siguiente RF-ID de la lista.

`--escenario <RF-ID> --cerrar-lista` se puede usar solo (cuando ya cargaste todos los escenarios de esa sección en llamadas previas) o combinado con el último escenario en la misma llamada. El script rechaza cerrar una sección sin al menos un escenario, y rechaza agregar a una sección ya cerrada o a un `RF-ID` que no existe en este spec — si alguno falla, es señal de que la sección ya se cerró o de que falta agregar al menos un escenario antes.

### 4. Verificar completitud mecánica

```bash
<skill-dir>/scripts/crear_spec.sh check "<ruta_spec>"
```

Si reporta placeholders pendientes, son secciones RF sin cerrar: volvé al paso 3 para ese RF-ID. Repetí hasta que `check` confirme que no queda ninguno.

### 5. Aprobación del usuario

`check` en OK no alcanza para dar el spec por terminado: la completitud del *contenido* la aprueba el usuario, no el script. Presentale un **resumen objetivo** por cada `RF00N` (ID y nombre de cada escenario registrado, ej. `RF001E001: Alta exitosa`) y esperá su confirmación explícita.

Recién cuando el usuario apruebe, marcá el documento como completo:

```bash
<skill-dir>/scripts/crear_spec.sh aprobar "<ruta_spec>"
```

Si el usuario pide cambios, volvé al paso 3 antes de aprobar.

### 6. Entrega

Mostrale el archivo final al usuario.

## Skills relacionadas

- `/idea`: genera el PRD con `Estado: Completo` y los `RF00N` que esta skill consume como entrada obligatoria.
- `/entrevistar`: conduce cada entrevista del paso 3, una pregunta a la vez con recomendación.
