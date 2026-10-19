# dotskills

Workflows reutilizables para asistentes de programación: Codex, Claude Code y
Cursor.

`dotskills` reúne las instrucciones, comandos y scripts auxiliares que uso para
analizar tickets, planificar implementaciones, documentar proyectos y preparar
pull requests. El repositorio es público y el instalador registra las skills
globalmente como copias para Codex/Cursor y enlaces simbólicos para Claude Code.

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
- copia las skills a `~/.agents/skills/` para Codex y Cursor, y crea enlaces
  simbólicos en `~/.claude/skills/` para Claude Code;
- no sobrescribe archivos o directorios existentes;
- permite volver a ejecutar la instalación para actualizar los workflows.

## Dónde se instalan

Cada skill vive una sola vez en este repositorio, bajo `skills/<nombre>/`
(formato abierto [Agent Skills](https://agentskills.io)). El instalador copia
las skills a `~/.agents/skills/` para Codex y Cursor, y las symlinkea a
`~/.claude/skills/` para Claude Code.

| Herramienta | Invocación | Destino global |
| --- | --- | --- |
| Codex | `/cocinar` | `~/.agents/skills/` |
| Claude Code | `/cocinar` | `~/.claude/skills/` |
| Cursor | `/cocinar` | `~/.agents/skills/` |

Codex y Cursor comparten `~/.agents/skills/`, así que una sola copia por skill
alcanza para las dos. Claude Code lee `~/.claude/skills/`.

## Uso

La invocación es igual en las tres herramientas:

```text
/crear-ticket
/cocinar PROJ-1234
```

`PROJ-1234` es solamente un ejemplo neutro de un identificador de Jira.
Reemplázalo por el identificador real de tu proyecto.

## Actualizar y desinstalar

Para actualizar la instalación, vuelve a ejecutar el comando correspondiente.
El instalador hará `git pull --ff-only` sobre la copia almacenada en
`~/.local/share/dotskills` y refrescará los enlaces.

Para eliminar las copias y los enlaces creados por `dotskills`, ejecuta el
desinstalador desde la copia local:

```bash
sh ~/.local/share/dotskills/uninstall.sh all
```

También puedes eliminar un solo adaptador:

```bash
sh ~/.local/share/dotskills/uninstall.sh codex
sh ~/.local/share/dotskills/uninstall.sh claude
sh ~/.local/share/dotskills/uninstall.sh cursor
```

El desinstalador solo elimina copias marcadas por `dotskills` y enlaces que
apuntan a skills del repositorio. Conserva destinos existentes ajenos. Las
copias locales editadas también se eliminan al desinstalar.

## Workflows incluidos

### Ticket → pull request

| Workflow | Propósito |
| --- | --- |
| `crear-ticket` | Produce un ticket de Jira claro y accionable. |
| `consultar-ticket` | Consulta el título y la descripción de un ticket de Jira. |
| `crear-feature-flag` | Genera una propuesta de feature flag de Split.io a partir de un ticket Jira. |
| `cocinar` | Carga el contexto verificado de un ticket de Jira y hace handoff a `sdd` para continuar el flujo de desarrollo. |
| `crear-pr` | Prepara una pull request a partir de cambios implementados. |

### Documentación (Diátaxis)

| Workflow | Propósito |
| --- | --- |
| `documentar` | Coordina la creación o mejora de documentación con Diátaxis. |
| `crear-readme` | Genera o actualiza un README.md a partir del análisis del proyecto. |

### Autoría y validación de skills

| Workflow | Propósito |
| --- | --- |
| `crear-skill` | Crea un nuevo skill conforme al estándar Agent Skills. |
| `validar-skill` | Audita un skill existente contra el estándar y las convenciones del repo. |

### Transversal

| Workflow | Propósito |
| --- | --- |
| `entrevistar` | Recorre decisiones pendientes una por una hasta alcanzar entendimiento compartido. |
| `consultar-metricas` | Muestra cuántas veces se invocó cada skill instalado, a partir de un hook de Claude Code que hay que configurar una vez. |
| `commit` | Analiza, propone y gestiona commits siguiendo Conventional Commits. |

## Dependencias de los workflows

Los archivos se pueden instalar sin configurar servicios externos, pero algunos
workflows esperan capacidades adicionales:

- `cocinar` espera un workflow de consulta de tickets (`consultar-ticket`),
  `consultar-subtareas`, acceso al contexto de Jira y la skill `sdd`; después
  del handoff, `sdd` es responsable del análisis, la planificación, la
  implementación y la pull request;
- `crear-feature-flag` usa `consultar-ticket` para obtener el contexto Jira
  antes de generar la propuesta de Split.io;
- `documentar` organiza el trabajo internamente en sub-skills privadas
  (clasificación, tutoriales, guías, referencia, explicaciones y validación)
  anidadas en `skills/documentar/skills/`; no se instalan ni se invocan por
  separado;
- `crear-skill` se completa habitualmente validando el resultado con
  `validar-skill`;
- `crear-pr` necesita un repositorio Git y acceso a GitHub para abrir la PR;
- `consultar-metricas` solo mide uso en Claude Code, y solo después de agregar a mano el hook que él mismo indica en `~/.claude/settings.json` — sin eso, el log de uso queda vacío;

Estas dependencias pueden existir en tu instalación del asistente o en el
proyecto donde trabajas. `dotskills` no crea credenciales ni configura
conectores de Jira, Atlassian o GitHub.

## Estructura del repositorio

```text
dotskills/
├── skills/               # Cada skill vive una sola vez: <nombre>/SKILL.md
│   └── <nombre>/         # + scripts/, references/, assets/, recursos propios
│                         # copiado a ~/.agents/skills/ y symlinkeado a ~/.claude/skills/
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
separada — así queda claro que no es invocable por su cuenta. `install.sh`
copia las skills de `skills/<nombre>/` a `~/.agents/skills/` y mantiene los
symlinks de `~/.claude/skills/`.

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

Reinicia la herramienta y revisa `~/.agents/skills/`. Comprobá que la skill
exista ahí como carpeta real con `SKILL.md`.

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
