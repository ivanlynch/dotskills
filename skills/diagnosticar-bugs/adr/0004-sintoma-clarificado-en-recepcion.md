# 0004. Síntoma clarificado en Recepción, persistido desde `init`

## Estado

Aceptada

## Contexto

`SINTOMA_USUARIO` recién se persistía en `DIAGNOSTICO.md` al cerrar la
Fase 2 (Construir bucle de feedback), vía `estado.sh acumular` — ver
`fases/construir-bucle/TEMPLATE.md`. Cualquier investigación interrumpida
entre la Fase 1 (Iniciar investigación) y el cierre de la Fase 2 —una
ventana amplia: reproducir, construir el comando, validar el bucle—
quedaba sin nada persistido. `estado.sh listar` la mostraba como
`(sin síntoma registrado todavía)`.

Esto es un problema real para la Fase 0 (Recepción, ver ADR 0002): su
paso de comparación depende de tener un síntoma legible por investigación
listada, y las instrucciones no distinguían "no hay coincidencia" de "no
hay con qué comparar" para esas entradas.

Además, el síntoma que dispara todo el flujo puede llegar impreciso —
vago, o mezclando más de un bug en una sola descripción— lo cual también
debilita la comparación de Recepción, independientemente de cuándo se
persista.

## Decisión

1. Recepción gana un paso de clarificación (paso 2, antes de comparar):
   si la descripción de la persona ya es precisa, no se pregunta nada por
   preguntar; si no, se usa el skill `/entrevistar` para llegar a un
   síntoma claro y comparable, en vez de reinventar una lógica de
   preguntas propia en este flujo.
2. `estado.sh init` pasa a exigir el síntoma ya clarificado como
   argumento obligatorio, y lo graba como `SINTOMA_USUARIO` en la
   cabecera de `DIAGNOSTICO.md` en el momento de crear la investigación
   — no recién al cerrar la Fase 2. **No puede existir una investigación
   sin síntoma registrado**: es una regla, no un caso mejor cubierto —
   `init` sin ese argumento falla.

La Fase 2 sigue teniendo su propio `SINTOMA_USUARIO` en
`fases/construir-bucle.md` (acumulado después bajo su propia sección de
`DIAGNOSTICO.md`): no reemplaza al de la cabecera, lo refina — esa fase
sigue siendo responsable de confirmar que la reproducción coincide con lo
que la persona describió (capa semántica de
`fases/construir-bucle/INSTRUCCIONES.md`).

## Consecuencias

- `estado.sh listar` siempre tiene un síntoma real para comparar, desde
  el primer momento de toda investigación — `init` sin síntoma falla, así
  que no hay forma de crear una investigación sin uno. El texto
  `(sin síntoma registrado todavía)` que todavía imprime `cmd_listar` para
  un `DIAGNOSTICO.md` sin esa línea queda como fallback defensivo (un
  archivo corrupto o editado a mano), no como un estado esperado del
  flujo.
- `DIAGNOSTICO.md` termina con dos apariciones de `SINTOMA_USUARIO`: la de
  la cabecera (Fase 0/1) y la de la sección de Fase 2. `TEMPLATE.md`
  instruye copiar tal cual la de la cabecera en Fase 2, no redactarla de
  nuevo — reduce el riesgo de que las dos digan cosas distintas, aunque
  no lo elimina (alguien puede editar `fases/construir-bucle.md` a mano
  después). `cmd_listar` toma la primera (`grep -m1`), que es la más
  temprana — es la decisión correcta pase lo que pase con la segunda.
- El síntoma se colapsa a una sola línea antes de grabarse (mismo formato
  `CAMPO: valor` que ya usa `fases/construir-bucle/TEMPLATE.md`) — una
  descripción multilínea pierde saltos de línea en la cabecera. Si hace
  falta el detalle completo, sigue viviendo en `fases/construir-bucle.md`
  al cerrar la Fase 2.
- No cambia nada de la Fase 3 en adelante: el bucle de hipótesis (Fase 4)
  se construye sobre la reproducción minimizada de la Fase 3, no sobre
  `SINTOMA_USUARIO` directamente (ver
  `fases/reproducir-minimizar/INSTRUCCIONES.md`).
