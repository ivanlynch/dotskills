---
name: consultar-metricas
description: Muestra cuántas veces se invocó cada skill instalado, de más a menos usado, a partir de un log que llena un hook de Claude Code. Usar cuando el usuario pida ver estadísticas, métricas, conteo de uso o cuáles skills usa más o menos.
---

# Consultar Métricas

Muestra el uso acumulado de skills: cuántas veces se invocó cada uno. Los datos los junta un hook de Claude Code (`PreToolUse`, matcher `Skill`) que hay que configurar una sola vez — no es automático con solo instalar `dotskills`.

## Flujo

### 1. Mostrar el uso acumulado

Ejecutar siempre primero:

```bash
<skill-dir>/scripts/ver_metricas.sh
```

- Si imprime una tabla `USOS | SKILL`: mostrarla tal cual, sin reformular los números.
- Si imprime `No hay registros de uso de skills todavía.`: no hay datos porque el hook nunca corrió. Seguir al paso 2 en vez de terminar acá — probablemente el hook no está configurado.

### 2. Sin datos: verificar y ofrecer configurar el hook

Antes de asumir que falta configuración, revisar si `~/.claude/settings.json` ya tiene un hook `PreToolUse` con matcher `Skill` apuntando a `<skill-dir>/scripts/registrar_uso_skill.sh` (resolvé `<skill-dir>` a la ruta real de este skill activo). Si ya está y aun así no hay datos, avisarle a la persona que el hook está configurado pero todavía no se invocó ningún skill desde que se agregó — no es un error.

Si el hook **no** está configurado, ofrecer agregarlo y, si la persona confirma, agregar exactamente este fragmento a `~/.claude/settings.json` — **fusionándolo** con lo que ya haya ahí (no pisar hooks u otras claves existentes; si `hooks.PreToolUse` ya tiene entradas, agregar este objeto al array en vez de reemplazarlo):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          { "type": "command", "command": "<skill-dir>/scripts/registrar_uso_skill.sh" }
        ]
      }
    ]
  }
}
```

Reemplazar `<skill-dir>` por la ruta absoluta real (normalmente algo como `~/.claude/skills/consultar-metricas`, symlinkeado por `install.sh` a `~/.local/share/dotskills/skills/consultar-metricas`). Avisar que hace falta reiniciar Claude Code para que tome el hook nuevo, y que recién a partir de ahí se va a empezar a acumular uso.

**No editar `settings.json` con una herramienta que reescriba el JSON entero** (arriesga perder claves que la persona ya tenía) — insertar el fragmento a mano, respetando el resto del archivo.

Solo funciona con Claude Code: Codex y Cursor no tienen, hoy, un mecanismo de hooks equivalente que este skill sepa aprovechar. Si la persona usa esos agentes, avisarle que este skill no puede medir su uso ahí.

## Formato del log

`<skill-dir>/scripts/registrar_uso_skill.sh` es el hook: nunca se invoca como parte de este flujo, lo corre Claude Code solo, en cada invocación de cualquier skill (no solo los de este repositorio). Cada línea de `$DOTSKILLS_HOME/metricas/uso_skills.log` tiene el formato `<timestamp ISO 8601 UTC>\t<skill>`; si el hook no logra identificar el nombre del skill en el payload que recibe, registra `desconocido` en vez de fallar — nunca bloquea la invocación real, ni siquiera con stdin vacío o malformado.

`$DOTSKILLS_HOME` toma la variable de entorno del mismo nombre si está seteada; si no, `$XDG_DATA_HOME/dotskills`; si tampoco, `~/.local/share/dotskills` — el mismo default que ya usa `install.sh` para la copia clonada del repo.
