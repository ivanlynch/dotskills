# 0003. Identidad de proyecto siempre a nivel de repo, sin excepción para monorepos

## Estado

Aceptada

## Contexto

`resolver_proyecto.sh` identifica el proyecto por su remoto git `origin`
(o, en su ausencia, por el hash del commit raíz — ver `identificador()`).
Nunca considera el path dentro del repo desde el que se invoca.

En un monorepo, dos bugs de subproyectos completamente distintos (ej.
`apps/web` y `apps/api`) comparten el mismo `<slug-proyecto>` y, por lo
tanto, la misma carpeta de investigaciones. `estado.sh listar` (Fase 0,
Recepción — ver ADR 0002) le muestra al agente, mezcladas, las
investigaciones de subproyectos que no tienen nada que ver entre sí. Esto
se reportó como problema en el
[issue #8](https://github.com/ivanlynch/dotskills/issues/8), que dejaba
abiertas dos direcciones sin decidir: incluir el subpath en la identidad,
o acotar `listar` a un área del monorepo.

## Decisión

No fragmentar la identidad de proyecto por subcarpeta, ni siquiera dentro
de un monorepo con subproyectos claramente separados. Un monorepo sigue
siendo **1 solo repo**, y la identidad se mantiene consistente con el
resto del diseño (remoto git / commit raíz, nunca path) sin una excepción
ad hoc para este caso.

Que `estado.sh listar` muestre investigaciones de subproyectos distintos
del mismo monorepo es el comportamiento esperado, no un bug — se cierra
el issue #8 sin cambios de código.

## Consecuencias

- Se descarta agregar el subpath a `resolver_identificador()`: hubiera
  requerido decidir dónde cae el límite entre "proyectos" dentro de un
  repo (¿primer nivel de carpeta? ¿el directorio con su propio
  `package.json`/`go.mod`?), una regla adicional y con casos borde
  propios, para un caso que ya tiene una salida manual (la comparación
  semántica de la Fase 0 sigue siendo responsabilidad de quien la corre).
- Tampoco se agrega un filtro opcional a `listar` por ahora: si en el
  futuro el ruido de un monorepo activo resulta un problema real y
  recurrente, se puede reabrir como una mejora acotada (filtrar la vista,
  sin tocar la identidad ni la carpeta), no como parte de esta decisión.
- La regla general "identidad de proyecto = repo entero, nunca
  fragmentada por subcarpeta" queda documentada acá porque es específica
  del diseño de `diagnosticar-bugs` (depende de `resolver_proyecto.sh`,
  que no existe en otras skills de este repositorio) — no es una
  convención del repositorio `dotskills` en general.
