# 0007. `estado.sh listar` vuelve, pero para recuperar un `<id>` perdido — no para detectar duplicados

## Estado

Aceptada

## Contexto

ADR 0005 sacó `estado.sh listar` (y `migrar`) porque el único uso que
tenía — comparar contra investigaciones abiertas para detectar
duplicados en la Fase "Recepción" — no se justificaba con un solo
usuario. Esa decisión sigue en pie: no hay razón para volver a
comparar síntomas ni para bloquear una investigación nueva por
parecerse a una vieja.

Pero `listar` no solo servía para eso. Era también la única forma
mecanizada de **ver qué investigaciones existen** para un proyecto.
Al sacarlo, se perdió esa capacidad de paso, sin que ADR 0005 la
haya evaluado — el ADR habla de duplicados, no de recuperación.

El problema quedó expuesto en una auditoría completa de la skill: el
`<id>` de una investigación (ej. `INV007`) vive solo en la
conversación — ningún paso lo anota en un lugar fácil de encontrar
después. Si la sesión se corta o el contexto se comprime y el `<id>`
se pierde, hoy la única forma de recuperarlo es ir a mano a
`$DIAGNOSTICOS_ROOT/<slug-proyecto>/` (un hash sha256, no legible) y
abrir cada `DIAGNOSTICO.md` a mano. Esto choca contra la premisa de
diseño declarada en `STATE_MACHINE.md`: que el estado "sobrevive a que
se corte la sesión".

## Decisión

Reintroducir `estado.sh listar`, con un propósito distinto y más
chico que el que tenía antes de ADR 0005:

- Imprime `<id>: <SINTOMA_USUARIO>`, una línea por investigación del
  proyecto actual (mismo criterio de identidad que el resto de los
  comandos).
- Es de solo lectura. No compara, no decide duplicados, no bloquea
  nada — el agente (o la persona) lo lee y decide.
- No se engancha a ningún flujo obligatorio. Fase 0 lo menciona como
  salida para el caso "perdí el `<id>` de algo que ya había
  empezado", no como un paso a correr siempre antes de `init`.

## Consecuencias

- Recupera la capacidad de recuperación sin revivir nada de lo que
  ADR 0005 sacó a propósito (comparación semántica, `migrar`,
  bloqueo de duplicados).
- Si en el futuro este skill pasa a usarse en equipo (el mismo
  supuesto que ADR 0005 identificó como el que justificaría volver a
  detectar duplicados), `listar` ya existe como base — pero decidir
  eso es una ADR aparte, no algo que esta reintroducción habilite por
  sí sola.
- `DIAGNOSTICOS_ROOT` sigue sin ningún mecanismo de archivado o
  limpieza: `listar` puede ir mostrando una lista cada vez más larga
  con el tiempo. No se aborda acá — es una preocupación de
  escalabilidad distinta, para revisar si llega a ser un problema
  real.
