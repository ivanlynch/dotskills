# 0006. Fusionar Recepción con Iniciar investigación

## Estado

Aceptada. Supera ADR 0002.

## Contexto

ADR 0002 separó "Preparación" en dos fases con responsabilidad única
cada una: Recepción (decidir si el bug ya tenía investigación abierta) e
Iniciar investigación (crear la investigación nueva). ADR 0005 le sacó a
Recepción la parte de detección de duplicados — este es un skill de un
solo usuario, no hay con quién colisionar — y la dejó con una única
responsabilidad restante: entrevistar hasta tener un síntoma claro. ADR
0005 consideró explícitamente volver a fusionar las dos fases y lo
descartó ("no hay razón para volver a fusionarlas — cada una conserva una
responsabilidad única: entrevistar vs. crear").

Esa razón ya no sostiene el peso de dos fases separadas. "Entrevistar
hasta tener un síntoma" y "correr `estado.sh init` con ese síntoma" son
dos pasos de una sola tarea corta, no dos responsabilidades que valga la
pena aislar en archivos distintos: no hay ninguna decisión de negocio
entre ambos (a diferencia de la Recepción original, que sí decidía algo
—match/nueva— antes de crear). Mantenerlas separadas agrega un archivo,
una entrada en la tabla de `SKILL.md` y un criterio de cierre intermedio
sin que ninguna fase downstream dependa de esa separación.

## Decisión

Eliminar la Fase "Recepción" (`fases/recepcion/`). Su única
responsabilidad restante —entrevistar hasta tener un síntoma claro— pasa
al primer paso de "Iniciar investigación", que ahora es la Fase 0.

Las fases 2 a 7 se renumeran a 1 a 6 en `SKILL.md` y en cada
`INSTRUCCIONES.md`/`TEMPLATE.md` que referenciaba un número de fase.

## Consecuencias

- El flujo vuelve a 7 fases (de las 8 que introdujo ADR 0002): Iniciar
  investigación, Construir bucle de feedback, Reproducir y minimizar,
  Formular hipótesis, Instrumentar, Corregir y testear, Limpiar.
- `STATE_MACHINE.md` pierde el estado `Recepcion` — el diagrama arranca
  directo en `IniciarInvestigacion`.
- No revive ninguna responsabilidad de ADR 0002 que ADR 0005 ya había
  eliminado (listar, comparar, migrar siguen sin existir).
- Si en algún momento este skill pasa a usarse en equipo (el supuesto que
  ADR 0005 identificó como el que justificaría volver a tener detección
  de duplicados), esa decisión trae de vuelta una fase separada con su
  propia responsabilidad — no hace falta revertir esta ADR para eso, una
  nueva Recepción se puede reintroducir sin depender de esta fusión.
