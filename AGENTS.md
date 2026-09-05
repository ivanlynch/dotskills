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

## Identidad de proyecto es siempre a nivel de repo

Donde una skill necesite identificar "en qué proyecto estoy" (ver
`skills/diagnosticar-bugs/scripts/resolver_proyecto.sh`), la identidad es
siempre el repo entero (remoto git / commit raíz) — nunca se fragmenta
por subcarpeta, ni siquiera dentro de un monorepo con subproyectos
claramente separados. Un monorepo sigue siendo 1 solo repo; ver
[issue #8](https://github.com/ivanlynch/dotskills/issues/8) para el
razonamiento completo.
