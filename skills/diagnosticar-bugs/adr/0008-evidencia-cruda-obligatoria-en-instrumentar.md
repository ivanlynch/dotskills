# 0008. Evidencia cruda obligatoria para marcar VEREDICTO en Instrumentar

## Estado

Aceptada

## Contexto

Cada hipótesis de la Fase 4 (Instrumentar) se cierra con un
`VEREDICTO` (`confirmada` o `descartada`), decidido comparando
`RESULTADO` (texto libre: qué observó el agente) contra la predicción
de `HIPOTESIS`. Ni `INSTRUCCIONES.md` ni `scripts/validar.sh` exigían
nunca que `RESULTADO` viniera acompañado de la salida cruda del
sondeo — era prosa libre, sin ningún artefacto verificable detrás.

Esto es una asimetría real con el resto de la skill. Las Fases 1 y 2
exigen pegar la corrida real tal cual, bajo `## Corrida real`
("es la prueba de que ya lo corriste al menos una vez, no una promesa
de que funcionaría" — `construir-bucle/TEMPLATE.md`). Instrumentar es
la única fase donde una afirmación central del diagnóstico (qué
hipótesis es la causa confirmada) se apoya únicamente en el criterio
declarado del agente, sin nada crudo que la respalde.

## Decisión

`EVIDENCIA` pasa a ser un quinto campo obligatorio en cada registro de
Instrumentar, junto a `ID`/`SONDEO`/`RESULTADO`/`VEREDICTO`: la ruta a
un archivo con la salida cruda del sondeo (log, transcripción de
debugger, captura de profiler) tal cual, no un resumen.

- La ruta se genera con `estado.sh ruta-evidencia <id> <ID_hipotesis>.txt`,
  un comando nuevo que crea (bajo demanda, igual que `fases/<fase>.md`)
  una carpeta `evidencia/` hermana de `fases/` dentro de la carpeta de
  la investigación.
- `validar.sh` exige que `EVIDENCIA` esté completo **y** que el
  archivo que referencia exista y no esté vacío (`[ -s "$evidencia" ]`)
  antes de aceptar la entrada como completa — sin eso, no hay `READY`
  posible, independientemente de qué diga `VEREDICTO`.
- Lo que el script sigue sin poder verificar (y no le corresponde) es
  que la evidencia realmente respalde el veredicto elegido — eso sigue
  siendo criterio del agente, igual que antes. Lo nuevo es que ese
  criterio ya no puede ejercerse sobre la nada: tiene que haber algo
  concreto en disco.

## Consecuencias

- Cada investigación acumula, además de `DIAGNOSTICO.md`, una carpeta
  `evidencia/` con un archivo por hipótesis instrumentada — confirmada
  o descartada. No se limpia en la Fase 6 (Limpiar): vive fuera del
  proyecto (en `$DIAGNOSTICOS_ROOT`), es parte del registro del
  diagnóstico, no instrumentación del código.
- `EVIDENCIA` guarda una ruta de archivo (un valor de una sola línea
  física), no el contenido crudo embebido en el `.md` de la fase — así
  no rompe la convención de "campo en mayúsculas = una línea física"
  que usa `scripts/validar.sh` en toda la skill, y evita el riesgo de
  que un log pegado inline con saltos de línea confunda el parseo por
  `ID:` de los registros siguientes.
- Investigaciones existentes con registros de Instrumentar ya
  acumulados (sin `EVIDENCIA`) no se migran — el campo nuevo solo
  aplica a hipótesis instrumentadas de acá en adelante.
