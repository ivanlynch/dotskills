---
name: idea
description: Transforma ideas e impulsos abstractos en un PRD (Documento de Requerimientos de Producto) funcional con problema, alcance y zona de exclusión. Úsala cuando el usuario presente una idea inicial, una nueva iniciativa o un requerimiento difuso sin especificación.
---

# Idea

Transforma ideas crudas, conceptos abstractos e impulsos de nuevas características en un **Documento de Requerimientos de Producto (PRD)** funcional y acotado mediante un proceso de entrevista interactivo.

## Flujo de Trabajo

El documento se completa con comandos, no editando el archivo a mano: cada respuesta confirmada de la entrevista se registra de inmediato con `crear_prd.sh`, y al final `check` confirma mecánicamente que no quedó ningún campo sin completar. No des el PRD por terminado por criterio propio — dejá que `check` lo confirme.

**Importante:** Mantené toda la entrevista 100% funcional. Prohibido mencionar tecnologías, arquitecturas, bases de datos o código.

### 1. Crear el archivo

```bash
<skill-dir>/scripts/crear_prd.sh init "<titulo_de_la_feature>" [ruta_de_salida]
```

Si omitís `ruta_de_salida`, el script guarda el PRD en `changes/<slug>/prd.md` dentro del repo del proyecto donde se está trabajando (no en este repo de skills), con `<slug>` en kebab-case derivado del título. `changes/<slug>/` es la carpeta de contexto de esta feature en curso: ahí se van a ir sumando los demás artefactos de las etapas siguientes (spec técnica, diseño, plan) a medida que existan skills para generarlos. No uses `docs/specs/`: esa carpeta es para el conocimiento permanente del producto una vez implementada la feature, no para el borrador en curso.

Guardá la ruta que imprime el script (`<ruta>`): la vas a usar en todos los pasos siguientes.

### 2. Entrevistar y registrar, campo por campo

Aplicá `/entrevistar` para cada punto, uno por vez con respuesta recomendada, y registrá la respuesta apenas quede confirmada — no esperes a tener todo el PRD para empezar a guardar:

1. Entrevistá al usuario para entender el **Problema / Fricción**. Cuando tengas un entendimiento total, registralo:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --problema "<texto confirmado>"
   ```
2. Entrevistá al usuario para entender el **Objetivo & Resultado Esperado**. Cuando tengas un entendimiento total, registralo:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --objetivo "<texto confirmado>"
   ```
3. Entrevistá al usuario por cada paso del **Flujo Principal** (happy path). Puede tener uno o varios pasos secuenciales; por cada uno que confirme, registralo (una llamada por paso, en orden):
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --paso "<paso confirmado>"
   ```
   Después de cada paso registrado, preguntá explícitamente si hay alguno más — no des la lista por cerrada por tu cuenta ni cambies de tema sin preguntar. Recién cuando `/entrevistar` confirme que no hay más, cerrá la lista:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --paso --cerrar-lista
   ```
4. Entrevistá al usuario por cada **Requerimiento Funcional**: una capacidad atómica y verificable del sistema, no necesariamente un paso del flujo (también cubre reglas y restricciones que no aparecen en la narrativa del happy path, como validaciones o casos límite). Por cada uno que confirme, registralo con un título corto y una descripción — el script le asigna automáticamente el próximo ID `RF-00N`:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --requerimiento "<título corto>" "<descripción confirmada>"
   ```
   Después de cada requerimiento registrado, preguntá explícitamente si hay alguno más. Recién cuando `/entrevistar` confirme que no hay más, cerrá la lista:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --requerimiento --cerrar-lista
   ```
5. Entrevistá al usuario por cada elemento de la **Zona de Exclusión**. Por cada uno que confirme, registralo (una llamada por exclusión):
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --exclusion "<exclusión confirmada>"
   ```
   Después de cada exclusión registrada, preguntá explícitamente si hay alguna más. Recién cuando `/entrevistar` confirme que no hay más, cerrá la lista:
   ```bash
   <skill-dir>/scripts/crear_prd.sh add "<ruta>" --exclusion --cerrar-lista
   ```

`--cerrar-lista` se puede usar solo (sin texto, como en los ejemplos de arriba) o combinado con el último ítem en la misma llamada si ya sabés de antemano que es el último. `add` rechaza reemplazar un campo único ya completado, y rechaza `--cerrar-lista` si la lista quedaría vacía — si alguno falla, es señal de que el paso ya se hizo o de que falta agregar al menos un ítem antes de cerrar.

### 3. Verificar completitud mecánica

```bash
<skill-dir>/scripts/crear_prd.sh check "<ruta>"
```

Si reporta placeholders pendientes, volvé al paso 2 y completá el campo faltante con `/entrevistar`. Repetí hasta que `check` confirme que no queda ninguno. Esto es completitud mecánica (¿están todos los campos rellenos?), no aprobación del contenido — no cambia el `Estado` del documento.

### 4. Aprobación del usuario

`check` en OK no alcanza para dar el PRD por terminado: la completitud del *contenido* la aprueba el usuario, no el script. Presentale un **resumen objetivo** de lo que va a hacer esta tarea (problema, objetivo, flujo principal, cada requerimiento con su ID `RF-00N`, y las exclusiones) y esperá su confirmación explícita.

Recién cuando el usuario apruebe, marcá el documento como completo:

```bash
<skill-dir>/scripts/crear_prd.sh aprobar "<ruta>"
```

Esto cambia `**Estado:** Borrador` a `**Estado:** Completo` en el archivo. Si el usuario pide cambios en el resumen, volvé al paso 2 antes de aprobar.

### 5. Entrega

Mostrale el archivo final al usuario.

## Skills relacionadas

- `/entrevistar`: conduce cada entrevista del paso 2, una pregunta a la vez con recomendación.
