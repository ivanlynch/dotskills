---
name: crear-skill
description: Crea un nuevo skill (para Claude Code, Codex o Cursor) que cumple estrictamente la especificación abierta Agent Skills (agentskills.io) — valida nombre, descripción y campos de frontmatter, organiza scripts/references/assets, aplica progressive disclosure y deja el directorio listo bajo skills/<nombre>/. Úsala cuando el usuario quiera crear, generar o scaffoldear un nuevo skill, comando o slash command para este repositorio.
---

# Crear Skill

Genera un skill nuevo, autocontenido, que cumple **obligatoriamente** cada regla de la [especificación Agent Skills](https://agentskills.io/specification) (copia completa en `references/especificacion.md`). No aproximes ni relajes ninguna regla del frontmatter: son validables mecánicamente y un skill inválido puede fallar en silencio en alguna de las herramientas.

## Flujo

### 1. Reunir el objetivo del skill

Identifica qué hace el skill y en qué momento un agente debería usarlo. Si hay ambigüedad sobre el alcance, el nombre o el comportamiento esperado, invoca `/entrevistar` con una pregunta por vez y una recomendación breve. No inventes alcance no confirmado.

### 2. Elegir y validar el nombre (`name`)

Reglas obligatorias del campo `name`:

- 1 a 64 caracteres.
- Solo minúsculas unicode alfanuméricas (`a-z`, `0-9`) y guiones (`-`).
- No puede empezar ni terminar con guion.
- No puede tener guiones consecutivos (`--`).
- Debe coincidir exactamente con el nombre del directorio que lo contiene.

Convención de este repositorio (no exigida por el estándar, pero obligatoria acá para consistencia): verbo + sustantivo en español, kebab-case, igual que `crear-ticket`, `crear-pr`, `validar-skill`. Si el usuario propone un nombre inválido, rechazalo y proponé una alternativa que cumpla las reglas antes de seguir.

### 3. Redactar la descripción (`description`)

Reglas obligatorias del campo `description`:

- 1 a 1024 caracteres, no vacía.
- Debe describir **qué** hace el skill **y cuándo** usarlo — las dos cosas, no solo una.
- Debe incluir palabras clave específicas que ayuden a un agente a decidir si activarla.

Ejemplo bueno: *"Extrae texto y tablas de PDFs, completa formularios PDF y combina varios PDFs. Usar cuando se trabaje con documentos PDF o el usuario mencione PDFs, formularios o extracción de documentos."*
Ejemplo malo (rechazar si el usuario propone algo así): *"Ayuda con PDFs."*

### 4. Decidir los campos opcionales del frontmatter

Evaluá cada uno; no agregues ninguno sin necesidad real:

| Campo | Regla obligatoria si se usa |
| --- | --- |
| `license` | Nombre de licencia corto, o referencia a un archivo de licencia incluido en el skill. |
| `compatibility` | 1 a 500 caracteres. Solo si el skill tiene requisitos reales de entorno (producto específico, paquetes de sistema, acceso a red). La mayoría de los skills **no** necesitan este campo. |
| `metadata` | Mapa string→string. Usá claves razonablemente únicas para evitar choques con otros skills o herramientas. |
| `allowed-tools` | String separado por espacios con las herramientas pre-aprobadas. Campo experimental: su soporte varía entre agentes. |

### 5. Redactar el cuerpo del `SKILL.md`

El cuerpo no tiene restricciones de formato, pero seguí estas reglas obligatorias de este repositorio y del estándar:

- Escribilo en español, con la misma voz que el resto de los skills del repo (instrucciones directas, sin relleno).
- Incluí: instrucciones paso a paso, ejemplos de entrada/salida cuando aplique, y casos borde relevantes.
- **Mantené el `SKILL.md` completo por debajo de 500 líneas** y el cuerpo (sin contar frontmatter) por debajo de ~5000 tokens — el agente carga todo el archivo entero al activar el skill. Si el contenido crece más, movelo a `references/` y dejá solo un puntero en el cuerpo.
- Si el skill invoca a otro skill de este repo, referencialo con el prefijo `/nombre-del-skill` (convención ya establecida en `cocinar`, `idea`, `spec`, etc.).

### 6. Organizar directorios opcionales

Solo creá los que el skill realmente necesite:

- **`scripts/`** — código ejecutable en bash (no Python ni otro runtime que requiera instalar un intérprete aparte). Debe ser autocontenido o documentar claramente sus dependencias, incluir mensajes de error útiles y manejar casos borde sin romper. Si otro skill de este repo ya necesita el mismo script y ese otro skill es su dueño natural, referencialo por nombre de skill vecino en vez de duplicarlo. Si en cambio el script solo tiene sentido dentro del flujo de otro skill y no se usa de forma independiente, no lo bundlees como skill aparte: movelo a `references/`/`scripts/` de la skill dueña (ver `cocinar`, que absorbió así el análisis de alcance y la ejecución de tareas). Todo script `<nombre>.sh` necesita su test en `scripts/tests/<nombre>.sh` (bash puro, sin frameworks externos) antes de dar el skill por terminado.
- **`references/`** — documentación detallada que el agente carga solo cuando la necesita (p. ej. `REFERENCE.md`, o archivos por dominio). Mantené cada archivo enfocado en un tema.
- **`assets/`** — recursos estáticos: plantillas, imágenes, datos de referencia.

### 7. Referenciar archivos correctamente

- Usá siempre rutas relativas desde la raíz del skill (`references/archivo.md`, `scripts/script.sh`).
- Mantené las referencias a un nivel de profundidad desde el `SKILL.md`. No encadenes referencias a referencias.
- Para invocar un script bundleado, usá el patrón ya establecido en el repo: `<skill-dir>/scripts/archivo.sh` (el agente resuelve `<skill-dir>` por su propio contexto de skill activo; no hay variable de entorno portable entre Claude Code, Codex y Cursor para esto).

### 8. Crear el directorio del skill

Escribí el resultado directamente bajo `skills/<name>/` en este repositorio (nunca en `core/`, `claude/`, `codex/` ni `cursor/` — esas carpetas ya no existen; `skills/` es la única fuente y `install.sh` la symlinkea a `~/.claude/skills/` y `~/.agents/skills/` sin copiar nada). No modifiques `install.sh` ni `uninstall.sh`: ya recorren todo lo que exista bajo `skills/*` de forma genérica.

### 9. Validar antes de terminar

No audites el resultado vos mismo: invocá `/validar-skill <name>` sobre el skill recién creado y esperá su veredicto. Es la única fuente de verdad del checklist — no lo repitas acá. Si `/validar-skill` deja puntos pendientes, resolvelos (editando el skill o respondiendo lo que te pregunte) y volvé a correrlo hasta que el resultado sea completo.

## Reglas de calidad

- No inventes campos de frontmatter fuera de los seis que define el estándar (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`).
- No relajes ninguna regla de `name` o `description` "porque total funciona igual": son las dos que los agentes leen siempre, para todos los skills, al arrancar.
- No dupliques contenido ni scripts que ya viven en otro skill del repo — referencialos.
- No des la tarea por terminada sin un veredicto completo de `/validar-skill`.
