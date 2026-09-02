---
name: validar-skill
description: Audita un skill existente de este repositorio (skills/<nombre>/) contra el estándar Agent Skills (agentskills.io) y las convenciones propias del repo, con un checklist persistido de forma determinística en un script — no en la interpretación libre del agente. Úsala después de crear o modificar un skill, antes de darlo por terminado.
---

# Validar Skill

Audita `skills/<name>/` punto por punto contra `validaciones.md`. El veredicto lo decide el script (`scripts/validar_skill.sh`), no la memoria del agente: cada corrida recalcula un hash del contenido del skill evaluado y, si cambió desde la última auditoría, **reinicia todo el checklist a `PENDING`** — ningún punto marcado sobrevive a una edición posterior, porque esa edición pudo invalidarlo.

## Flujo

### 1. Inicializar

Ejecutar siempre primero, incluso si ya se corrió antes en esta sesión:

```bash
<skill-dir>/scripts/validar_skill.sh init <name>
```

Si el contenido no cambió desde el último `init`, conserva el estado y muestra el resumen actual. Si cambió (o es la primera vez), reinicia todos los puntos de `validaciones.md` a `PENDING` y lo indica explícitamente (la cantidad exacta depende de la versión vigente del checklist — no la hardcodees).

### 2. Verificar mecánicamente lo que se pueda

Leer `<skill-dir>/../validaciones.md` para el detalle de cada punto (por qué existe, qué exactamente valida). Para cada ID en `pending`, intentar resolverlo **sin preguntar al usuario**, inspeccionando el skill evaluado: contar caracteres del `name`/`description`, chequear el charset, contar líneas del `SKILL.md`, verificar si existen `scripts/`/`references/`/`assets/`, revisar si las referencias usan rutas relativas de un nivel, etc.

```bash
<skill-dir>/scripts/validar_skill.sh pending <name>
```

Por cada punto resuelto, marcarlo de inmediato:

```bash
<skill-dir>/scripts/validar_skill.sh mark <name> <id> DONE "<justificación breve>"
<skill-dir>/scripts/validar_skill.sh mark <name> <id> NA "<por qué no aplica>"
```

Usar `NA` únicamente para puntos condicionales cuyo campo/directorio no existe en el skill evaluado (ver `validaciones.md`). Todo lo demás es `DONE` o queda `PENDING`.

### 3. Entrevistar lo genuinamente ambiguo

Volver a correr `pending <name>`. Lo que siga ahí es, por definición, algo que no se pudo resolver leyendo el skill (p. ej. "¿la descripción es lo bastante específica?", "¿el requisito de `compatibility` es real o preventivo?"). Para cada uno de esos puntos, invocar `/entrevistar`: una pregunta por vez, con recomendación, esperar la respuesta, y recién ahí marcar `DONE` o `NA` con `mark`.

No entrevistes por puntos que ya deberían haberse resuelto en el paso 2 — releé el skill antes de preguntar.

### 4. Repetir hasta veredicto completo

```bash
<skill-dir>/scripts/validar_skill.sh status <name>
```

Repetir los pasos 2–3 hasta que el resumen diga `VEREDICTO: COMPLETO`. Si en el medio se edita el skill evaluado (para corregir algo que falló), volver al paso 1 — el próximo `init` va a detectar el cambio y reiniciar todo el checklist automáticamente; no hace falta forzar nada a mano.

### 5. Reportar

Mostrar como resultado final la salida de `status <name>` tal cual la imprime el script (no la reescribas ni la resumas de forma libre): es la única fuente de verdad determinística de esta auditoría.

## Notas

- El estado de la auditoría vive en `TMPDIR`, fuera del repo (mismo patrón que `workflow_state.sh` de `cocinar`) — nunca se comitea nada de esto.
- `validaciones.md` es la definición estática del checklist, no cambia por corrida. Si el estándar Agent Skills se actualiza, editá `validaciones.md` (y `references/especificacion.md`) directamente; el próximo `init` de cualquier skill lo va a usar.
- El script rechaza marcar un `id` que no exista en `validaciones.md`, y rechaza `mark` si el hash del skill evaluado no coincide con el del último `init` — no hay forma de que el estado quede desincronizado del contenido real.
