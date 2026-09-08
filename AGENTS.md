# Instrucciones para agentes

Reglas de trabajo en `dotskills`, para cualquier asistente (Claude Code,
Codex, Cursor) que opere sobre este repositorio.

## Flujo de git: rama + PR, nunca push directo a `main`

Todo cambio de código o contenido de skills se integra vía pull request.
Creá una rama, commiteá ahí, pusheala y abrí la PR — no empujes commits
directo a `main`, ni siquiera para un cambio chico y ya validado con
tests. El historial de este repo es consistentemente por PR (`git log
--merges`); un push directo rompe ese patrón aunque el contenido del
cambio sea correcto. Mergeá la PR solo cuando el usuario lo pida
explícitamente para esa PR puntual — abrirla no implica permiso para
mergearla.

## Branches: nombre en Conventional Commits

**Obligatorio.** El nombre de la rama sigue el mismo tipo que
Conventional Commits, como prefijo: `tipo/descripción-corta` (ej.
`feat/nueva-skill-nueva-funcionalidad`, `fix/tal-cosa`,
`docs/agents-instructions`).

## Pull requests: título en Conventional Commits

El título de toda PR sigue [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/): `tipo(scope):
descripción` (ej. `docs(diagnosticar-bugs): agregar ADR 0003`). El scope,
cuando aplica, es el nombre de la skill afectada.

## Commits: identidad real de quien pide el cambio, nunca un agente

**Obligatorio.** Todo commit se hace con la identidad git (`user.name` /
`user.email`) de la persona que pidió el cambio — nunca con una identidad
de agente/bot (ej. "claude"). No se modifica la configuración de git para
simular otra identidad: se usa la que ya está configurada en el entorno
donde corre el agente. Tampoco se agregan líneas de coautoría/atribución
a un agente en el mensaje del commit.

## Commits: Conventional Commits

Los mensajes de commit siguen [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/): `tipo(scope):
descripción` en el asunto (`feat`, `fix`, `docs`, `refactor`, `test`,
`chore`, etc.), cuerpo opcional explicando el "por qué". Mismo criterio
de scope que en las PRs.

## Issues para problemas identificados sin solución decidida

Cuando encuentres un problema real pero la solución todavía no está
decidida (hay más de una dirección válida, o requiere alineación con el
usuario), documentalo como issue de GitHub en vez de improvisar una
solución sobre la marcha. Estructura consistente:

- `## Contexto` — qué pasa y por qué, con referencias a archivos y líneas
  concretas del repo.
- `## Impacto concreto` — a quién o qué afecta, y cómo se manifiesta.
- `## Alcance de este issue` — dejar explícito que **no** se está
  decidiendo la solución todavía; listar direcciones posibles sin
  comprometerse a ninguna.
- `## Referencias` — archivos y ADRs relevantes.

Ver los issues [#8](https://github.com/ivanlynch/dotskills/issues/8),
[#10](https://github.com/ivanlynch/dotskills/issues/10) y
[#11](https://github.com/ivanlynch/dotskills/issues/11) como ejemplos del
patrón.

## Issues: label de la skill correspondiente

Todo issue se etiqueta con el nombre de la skill a la que corresponde
(ej. `diagnosticar-bugs`). Si el label todavía no existe en el
repositorio, crealo primero (`gh label create <nombre-skill>`) antes de
abrir el issue.

## Redacción de contenido de skills: criterios de revisión

Al escribir o revisar `INSTRUCCIONES.md`, `TEMPLATE.md`, o cualquier
otro contenido de una skill (incluidos ejemplos y fixtures de test que
representan contenido real, no solo formato), chequeá:

1. **Coherencia.** La información no se contradice entre archivos (ej.
   `STATE_MACHINE.md` vs `INSTRUCCIONES.md` de una fase), y ninguna
   rama de un flujo omite un paso que sí aparece en la otra rama.
2. **Palabras simples.** Evitar jerga o calcos del inglés sin necesidad
   (ej. "seam", "ejercitar") cuando la idea se puede describir en
   lenguaje llano sin perder precisión.
3. **Información concisa, pero no a costa de la claridad.** Conciso
   significa sacar redundancia real — decir lo mismo dos veces, texto
   que no aporta nada nuevo — no comprimir una oración hasta romper su
   gramática o volverla difícil de leer. **No hay ningún motivo para
   economizar caracteres**: un ejemplo o una hipótesis tiene que leerse
   natural, no como una nota telegráfica.
4. **Instrucciones lógicas.** El orden de los pasos no puede exigir
   información que todavía no existe (ej. pedir datos de un usuario
   logeado antes del paso de login), y ninguna rama de un flujo se
   salta un paso necesario que la otra rama sí tiene.
5. **Mecanizar lo que se pueda mecanizar.** Si un paso se puede resolver
   con un script (grep, un validador, `estado.sh acumular`) en vez de
   depender del criterio del agente en cada corrida, mecanizarlo —
   mismo patrón que ya usan las fases de `diagnosticar-bugs` con
   `iniciar.sh`/`validar.sh`.
