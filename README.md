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

| Herramienta | Invocación | Destino global |
| --- | --- | --- |
| Codex | `$plan` | `~/.codex/skills/` |
| Claude Code | `/plan` | `~/.claude/skills/` y `~/.claude/commands/` |
| Cursor | `/plan` | `~/.cursor/commands/` |

Los comandos globales de Cursor dependen de la detección de comandos de la
versión instalada. Si no aparecen, reinicia Cursor y revisa la sección de
[solución de problemas](#solución-de-problemas). Cursor documenta los comandos
personalizados como archivos Markdown en `.cursor/commands`; también existe una
carpeta global `~/.cursor/commands`, aunque algunas versiones han tenido
problemas para detectarla.

## Uso

### Codex

Después de instalar el adaptador, las skills se invocan con `$`:

```text
$analizar-alcance
$plan
$crear-ticket
$cocinar PROJ-1234
```

### Claude Code

Claude Code usa comandos slash y skills:

```text
/analizar-alcance
/plan
/crear-ticket
/cocinar PROJ-1234
```

### Cursor

Los comandos aparecen en el menú slash de Agent:

```text
/analizar-alcance
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

| Workflow | Propósito |
| --- | --- |
| `analizar-alcance` | Determina si un ticket es independiente o debe dividirse. |
| `cocinar` | Orquesta el flujo completo desde un ticket hasta una pull request. |
| `crear-pr` | Prepara una pull request a partir de cambios implementados. |
| `crear-readme` | Genera o mejora un README de proyecto. |
| `crear-ticket` | Produce un ticket de Jira claro y accionable. |
| `documentar` | Coordina documentación técnica con Diátaxis. |
| `documentar-readme` | Especializa la creación o mejora de un README. |
| `implementar-plan` | Ejecuta las tareas de un plan persistido. |
| `implementar-tarea` | Ejecuta y verifica una tarea individual. |
| `plan` | Convierte un alcance confirmado en tareas implementables. |

## Dependencias de los workflows

Los archivos se pueden instalar sin configurar servicios externos, pero algunos
workflows esperan capacidades adicionales:

- `cocinar` espera un workflow de consulta de tickets (`consultar-ticket`),
  entrevistas y acceso al contexto de Jira;
- `plan` utiliza `crear-ticket` para producir las tareas;
- `documentar` delega en clasificación, guías, referencias y validación;
- `crear-pr` necesita un repositorio Git y acceso a GitHub para abrir la PR;
- los scripts de estado requieren Python 3.

Estas dependencias pueden existir en tu instalación del asistente o en el
proyecto donde trabajas. `dotskills` no crea credenciales ni configura
conectores de Jira, Atlassian o GitHub.

## Estructura del repositorio

```text
dotskills/
├── core/                 # Definiciones de workflows compartidas
├── scripts/              # Scripts auxiliares reutilizables
├── codex/skills/         # Skills y metadatos específicos de Codex
├── claude/skills/        # Adaptadores de skills para Claude Code
├── claude/commands/      # Comandos slash para Claude Code
├── cursor/commands/      # Comandos slash para Cursor
├── cursor/rules/         # Reglas de Cursor
├── install.sh            # Instalador global
└── uninstall.sh          # Desinstalador de enlaces
```

La implementación de Codex conserva sus metadatos `agents/openai.yaml`. Los
adaptadores de Claude Code y Cursor contienen el mismo flujo expresado con sus
convenciones de invocación.

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

### Cursor no muestra los comandos

Reinicia Cursor por completo y revisa `~/.cursor/commands/`. La detección de
comandos globales ha tenido regresiones en algunas versiones; como diagnóstico,
comprueba que los archivos `.md` existan y que sean enlaces simbólicos hacia
`~/.local/share/dotskills/cursor/commands/`.

### Claude Code o Codex no muestran una skill

Comprueba que el enlace exista en la carpeta global correspondiente y vuelve a
abrir la herramienta. También puedes forzar una actualización ejecutando de
nuevo el instalador.

## Documentación relacionada

- [Comandos de Claude Code](https://code.claude.com/docs/en/commands)
- [Comandos de Cursor](https://docs.cursor.com/en/agent/chat/commands)
- [Reglas de Cursor](https://docs.cursor.com/context/rules)
- [Incidencia de comandos globales de Cursor](https://forum.cursor.com/t/commands-are-not-detected-in-the-global-cursor-directory/150967)
