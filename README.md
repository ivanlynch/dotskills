# dotskills

Workflows reutilizables para asistentes de programación: Codex, Claude Code y
Cursor.

`dotskills` reúne las instrucciones, comandos y scripts auxiliares que uso para
analizar tickets, planificar implementaciones, documentar proyectos y preparar
pull requests. El repositorio es público y el instalador los registra de forma
global mediante enlaces simbólicos.

## Instalación rápida

Requiere `git` y una shell compatible con POSIX. Para instalar todos los
adaptadores:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- all
```

Para instalar solo un adaptador:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- codex
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- claude
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ivanlynch/dotskills/main/install.sh)" -- cursor
```

El instalador:

- clona o actualiza el repositorio en `~/.local/share/dotskills`;
- crea enlaces simbólicos en las carpetas globales de cada herramienta;
- no sobrescribe archivos o directorios existentes;
- permite volver a ejecutar la instalación para actualizar los workflows.

## Dónde se instalan

Cada skill vive una sola vez en este repositorio, bajo `skills/<nombre>/`
(formato abierto [Agent Skills](https://agentskills.io)). El instalador no
copia ese contenido: lo symlinkea a las rutas que cada herramienta lee de
forma nativa.

| Herramienta | Invocación | Destino global |
| --- | --- | --- |
| Codex | `/plan` | `~/.agents/skills/` |
| Claude Code | `/plan` | `~/.claude/skills/` |
| Cursor | `/plan` | `~/.agents/skills/` |

Codex y Cursor comparten `~/.agents/skills/` (ambos lo leen nativamente), así
que un solo enlace por skill alcanza para las dos. Claude Code solo lee
`~/.claude/skills/`.

## Uso

La invocación es igual en las tres herramientas:

```text
/idea
/spec
/plan
/crear-ticket
/cocinar PROJ-1234
```

`PROJ-1234` es solamente un ejemplo neutro de un identificador de Jira.
Reemplázalo por el identificador real de tu proyecto.

## Actualizar y desinstalar

Para actualizar la instalación, vuelve a ejecutar el comando correspondiente.
El instalador hará `git pull --ff-only` sobre la copia almacenada en
`~/.local/share/dotskills` y refrescará los enlaces.

Para eliminar los enlaces creados por `dotskills`, ejecuta el desinstalador
desde la copia local:

```bash
sh ~/.local/share/dotskills/uninstall.sh all
```

También puedes eliminar un solo adaptador:

```bash
sh ~/.local/share/dotskills/uninstall.sh codex
sh ~/.local/share/dotskills/uninstall.sh claude
sh ~/.local/share/dotskills/uninstall.sh cursor
```

El desinstalador solo elimina enlaces simbólicos; no elimina archivos existentes
que no hayan sido creados por el instalador.

## Workflows incluidos

### Idea → especificación → plan

| Workflow | Propósito |
| --- | --- |
| `idea` | Transforma una idea abstracta en un PRD funcional (`changes/<slug>/prd.md`). |
| `spec` | Traduce un PRD aprobado en una especificación técnica con escenarios Gherkin (`changes/<slug>/spec.md`). |
| `plan` | Convierte una spec aprobada en un plan de tareas trazables a cada escenario (`changes/<slug>/plan.md`). |

### Ticket → pull request

| Workflow | Propósito |
| --- | --- |
| `crear-ticket` | Produce un ticket de Jira claro y accionable. |
| `cocinar` | Orquesta de punta a punta el análisis de alcance, la planificación interna, la implementación y la pull request de un ticket de Jira. |
| `crear-pr` | Prepara una pull request a partir de cambios implementados. |

### Documentación (Diátaxis)

| Workflow | Propósito |
| --- | --- |
| `documentar` | Coordina la creación o mejora de documentación con Diátaxis. |

### Autoría y validación de skills

| Workflow | Propósito |
| --- | --- |
| `crear-skill` | Crea un nuevo skill conforme al estándar Agent Skills. |
| `validar-skill` | Audita un skill existente contra el estándar y las convenciones del repo. |

### Transversal

| Workflow | Propósito |
| --- | --- |
| `entrevistar` | Recorre decisiones pendientes una por una hasta alcanzar entendimiento compartido. |

## Dependencias de los workflows

Los archivos se pueden instalar sin configurar servicios externos, pero algunos
workflows esperan capacidades adicionales:

- `cocinar` espera un workflow de consulta de tickets (`consultar-ticket`),
  entrevistas y acceso al contexto de Jira. El análisis de alcance, la
  planificación interna y la ejecución tarea por tarea viven como
  `references/` y `scripts/` propios de `cocinar` (no son skills invocables
  por separado: no dependen de Jira, pero tampoco tienen sentido fuera de
  este flujo);
- `spec` exige un PRD de `idea` con `Estado: Completo`; `plan` exige una spec
  de `spec` con `Estado: Completo` — cada etapa valida mecánicamente que la
  anterior esté aprobada antes de arrancar;
- `documentar` organiza el trabajo internamente en sub-skills privadas
  (clasificación, tutoriales, guías, referencia, explicaciones y validación)
  anidadas en `skills/documentar/skills/`; no se instalan ni se invocan por
  separado;
- `crear-skill` se completa habitualmente validando el resultado con
  `validar-skill`;
- `crear-pr` necesita un repositorio Git y acceso a GitHub para abrir la PR;
- los scripts de estado son bash puro, sin dependencias externas.

Estas dependencias pueden existir en tu instalación del asistente o en el
proyecto donde trabajas. `dotskills` no crea credenciales ni configura
conectores de Jira, Atlassian o GitHub.

## Estructura del repositorio

```text
dotskills/
├── skills/               # Cada skill vive una sola vez: <nombre>/SKILL.md
│   └── <nombre>/         # + scripts/, references/, assets/, recursos propios
│                         # symlinkeado a ~/.claude/skills/ y ~/.agents/skills/
├── install.sh            # Instalador global
└── uninstall.sh          # Desinstalador de enlaces
```

Cada `skills/<nombre>/` es un directorio autocontenido: si invoca scripts, van
en bash puro (sin Python, sin JSON, sin dependencias externas como `jq`) dentro
de su propio `scripts/`. Un skill que dependa de otro lo referencia por nombre
de skill vecino, nunca copiando el script. Cuando una skill solo tiene sentido
como parte del flujo de otra (por ejemplo, el análisis de alcance y la
ejecución tarea por tarea de `cocinar`), su contenido vive directamente en
`references/` y `scripts/` de la skill dueña en vez de existir como skill
separada — así queda claro que no es invocable por su cuenta. `install.sh` no
copia contenido en ningún punto: solo crea symlinks desde `skills/<nombre>/`
hacia las carpetas globales de cada herramienta.

## Desarrollo

Clona el repositorio y edita la variante correspondiente:

```bash
git clone https://github.com/ivanlynch/dotskills.git
cd dotskills
```

Antes de publicar cambios, comprueba la sintaxis de los scripts y prueba el
instalador con un `HOME` temporal para no modificar tu configuración real:

```bash
sh -n install.sh
sh -n uninstall.sh
HOME=/tmp/dotskills-test-home sh ./install.sh all
HOME=/tmp/dotskills-test-home sh ./uninstall.sh all
```

## Solución de problemas

### El instalador no puede clonar el repositorio

Comprueba que `git` esté instalado y que tu conexión pueda acceder a
`github.com`.

### Un archivo existente impide la instalación

El instalador no sobrescribe archivos reales. Haz una copia de seguridad del
archivo o directorio que ocupa el destino y vuelve a ejecutar el instalador.

### Cursor o Codex no muestran un skill

Reinicia la herramienta y revisa `~/.agents/skills/`. Comprobá que el skill
exista ahí como enlace simbólico hacia `~/.local/share/dotskills/skills/<nombre>/`.

### Claude Code no muestra una skill

Comprueba que el enlace exista en `~/.claude/skills/` y vuelve a abrir la
herramienta. También puedes forzar una actualización ejecutando de nuevo el
instalador.

## Documentación relacionada

- [Agent Skills (estándar abierto)](https://agentskills.io)
- [Skills en Claude Code](https://code.claude.com/docs/en/skills)
- [Skills en Codex](https://learn.chatgpt.com/docs/build-skills)
- [Skills en Cursor](https://cursor.com/docs/skills)
- [Reglas de Cursor](https://docs.cursor.com/context/rules)
