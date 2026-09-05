# 0005. Recepción sin detección de duplicados: solo entrevista + iniciar

## Estado

Aceptada. Supera ADR 0002.

## Contexto

ADR 0002 le dio a Recepción la responsabilidad de detectar si el bug
descrito ya tenía una investigación abierta en el proyecto: listar
(`estado.sh listar`), comparar manualmente, y retomar el `<id>` existente
si había match. ADR 0001 (id incremental) y ADR 0003 (identidad de
proyecto a nivel de repo) construyeron sobre esa base, y un ciclo
posterior de hardening agregó `estado.sh migrar` para reconciliar
identidad de proyecto tras un rename de `origin`.

Toda esa maquinaria resuelve un problema real solo si hay **más de una
persona (o sesión concurrente) trabajando el mismo bug sin coordinarse**.
Este skill lo usa una sola persona. El costo de la detección de
duplicados —un comando adicional, una capa de comparación manual, una
capa entera de edge cases (identidad de proyecto, rename de `origin`,
`(sin síntoma registrado todavía)`)— no se paga con un beneficio real en
este contexto: no hay nadie más con quien colisionar.

## Decisión

Recortar Recepción a una sola responsabilidad: entrevistar al usuario
hasta tener un síntoma claro, y pasar directo a Fase 1 a abrir la
investigación. Se elimina:

- `estado.sh listar` y `estado.sh migrar` (y `resolver_proyecto.sh
  slug-de`, que solo existía para `migrar`).
- La comparación manual contra investigaciones abiertas (paso 3 de la
  Recepción anterior) y sus casos borde (ambigüedad, coincidencia
  parcial, listas vacías por rename de `origin`).

Se mantiene: la Fase 0 se sigue llamando Recepción y sigue precediendo a
Fase 1 (no hay razón para volver a fusionarlas — cada una conserva una
responsabilidad única: entrevistar vs. crear). El síntoma sigue siendo
obligatorio en `init` (ADR 0004) — eso no dependía de la detección de
duplicados, es valioso por sí solo como registro del diagnóstico.

## Consecuencias

- Menos superficie: un comando menos en `estado.sh`, un paso menos en el
  flujo, cero lógica de comparación manual para mantener.
- Se pierde la protección contra abrir dos investigaciones para el mismo
  bug. Es una pérdida real si el contexto de uso cambia (más de una
  persona operando sobre el mismo repo) — en ese caso, revisar esta
  decisión.
- Los issues [#10](https://github.com/ivanlynch/dotskills/issues/10) y
  [#11](https://github.com/ivanlynch/dotskills/issues/11), que endurecían
  `listar`/`migrar`, quedan sin efecto: el código que arreglaban ya no
  existe.
- `fases/iniciar-investigacion/INSTRUCCIONES.md` ya no depende de que
  Recepción haya "confirmado que es nueva" — toda llamada a Fase 1 crea
  una investigación nueva, sin condición previa.
