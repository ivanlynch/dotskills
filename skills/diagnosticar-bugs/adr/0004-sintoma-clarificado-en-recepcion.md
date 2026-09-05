# 0004. Síntoma obligatorio desde `init`

## Estado

Aceptada. Contexto parcialmente superado por ADR 0005 (ya no se lista ni
compara contra investigaciones abiertas) y ADR 0006 (Recepción se
fusiona con Iniciar investigación) — la decisión de fondo, que no puede
existir una investigación sin síntoma registrado, se mantiene por su
propio mérito.

## Contexto

`SINTOMA_USUARIO` recién se persistía en `DIAGNOSTICO.md` al cerrar la
Fase 1 (Construir bucle de feedback), vía `estado.sh acumular` — ver
`fases/construir-bucle/TEMPLATE.md`. Cualquier investigación interrumpida
entre la Fase 0 (Iniciar investigación) y el cierre de la Fase 1 —una
ventana amplia: reproducir, construir el comando, validar el bucle—
quedaba con un `DIAGNOSTICO.md` sin ningún registro de qué bug se estaba
persiguiendo.

Además, el síntoma que dispara todo el flujo puede llegar impreciso —
vago, o mezclando más de un bug en una sola descripción.

## Decisión

1. Fase 0 (Iniciar investigación) entrevista a la persona hasta tener un
   síntoma claro y accionable — si la descripción ya es precisa, no se
   pregunta nada por preguntar; si no, se usa el skill `/entrevistar` en
   vez de reinventar una lógica de preguntas propia en este flujo.
2. `estado.sh init` pasa a exigir ese síntoma como argumento obligatorio,
   y lo graba como `SINTOMA_USUARIO` en la cabecera de `DIAGNOSTICO.md`
   en el momento de crear la investigación — no recién al cerrar la Fase
   1. **No puede existir una investigación sin síntoma registrado**: es
   una regla, no un caso mejor cubierto — `init` sin ese argumento falla.

La Fase 1 sigue teniendo su propio `SINTOMA_USUARIO` en
`fases/construir-bucle.md` (acumulado después bajo su propia sección de
`DIAGNOSTICO.md`): no reemplaza al de la cabecera, lo refina —
`TEMPLATE.md` instruye copiarlo tal cual, no redactarlo de nuevo. Esa
fase sigue siendo responsable de confirmar que la reproducción coincide
con lo que la persona describió (capa semántica de
`fases/construir-bucle/INSTRUCCIONES.md`).

## Consecuencias

- Todo `DIAGNOSTICO.md` tiene, desde el momento de su creación, un
  registro real de qué bug se está investigando — sirve como
  documentación del diagnóstico y como referencia para la Fase 1/2, sin
  depender de que ninguna fase posterior llegue a cerrarse.
- El síntoma se colapsa a una sola línea antes de grabarse (formato
  `CAMPO: valor` de una línea, mismo que usa
  `fases/construir-bucle/TEMPLATE.md`) — una descripción multilínea
  pierde saltos de línea en la cabecera. Si hace falta el detalle
  completo, sigue viviendo en `fases/construir-bucle.md` al cerrar la
  Fase 1.
- No cambia nada de la Fase 2 en adelante: el bucle de hipótesis (Fase 3)
  se construye sobre la reproducción minimizada de la Fase 2, no sobre
  `SINTOMA_USUARIO` directamente (ver
  `fases/reproducir-minimizar/INSTRUCCIONES.md`).
