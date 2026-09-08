<!--
Plantilla de la fase "instrumentar".

Instrucciones:
1. Leé los comentarios — son una guía de cómo completar cada sección.
2. Completá los campos, respetando este formato: los campos en
mayúsculas los lee scripts/validar.sh con un grep línea por línea (no
interpreta variaciones), así que mantené el nombre exacto y el valor
completo en una única línea física, pegado después de los dos puntos
("CAMPO: valor"). Ni siquiera una continuación de línea con "\"
funciona — grep no une líneas.

Este archivo puede vivir varias vueltas del loop de la fase (probar
una hipótesis, descartarla, probar la siguiente...), así que
scripts/iniciar.sh no lo pisa: cada vez que lo corrés agrega los
registros de las hipótesis nuevas que todavía no tengan uno, sin tocar
los que ya existen.

Cada hipótesis es un registro de 5 campos ("ID:", "SONDEO:",
"RESULTADO:", "EVIDENCIA:", "VEREDICTO:"), separado del siguiente por
una línea en blanco — no campos sueltos con el ID pegado al nombre
(nada de "SONDEO_H06:"). Como "SONDEO:"/"RESULTADO:"/"EVIDENCIA:"/
"VEREDICTO:" se repiten una vez por registro, scripts/validar.sh no
los busca en todo el archivo: primero encuentra el registro por su
"ID:" y recién ahí busca el campo, dentro de ese bloque.

-->

# Fase: Instrumentar

## Síntoma reportado por el usuario

<!-- Ya viene completo: lo precargó scripts/iniciar.sh copiándolo de
DIAGNOSTICO.md. No lo edites — es solo contexto para quien lea esta
fase después. -->

SINTOMA_USUARIO:

## Sondeos

<!-- Por cada registro de abajo (uno por cada hipótesis que ya generó
la Fase 3): la hipótesis vigente es la de menor ID que todavía no
tiene un VEREDICTO puesto ("confirmada" o "descartada") — no hace
falta ningún campo aparte que la señale, es el primer registro con
esos campos vacíos bajando por el archivo. Completá solo ese registro;
dejá vacíos los de las hipótesis que todavía no probaste.

SONDEO: qué instrumentaste (breakpoint, log dirigido, medición) —
cambiá una sola variable por vez. Preferencia de herramientas: (1)
debugger/inspección en REPL si el entorno lo permite, un breakpoint
vale más que diez logs; (2) logs dirigidos en los límites que
distinguen las hipótesis; nunca "loguees todo y hacé grep". Si usás
logs, etiquetalos con un prefijo único como [DEBUG-a4f2] — limpiar al
final se reduce a un solo grep; los logs sin etiqueta sobreviven, los
etiquetados se eliminan.

Rama de rendimiento: para regresiones de rendimiento, los logs suelen
ser incorrectos. Medí primero (tiempo cronometrado, performance.now(),
un profiler, o el plan de una consulta), y después hacé bisección.
Medí antes de corregir.

RESULTADO: qué observaste al correrlo, en tus propias palabras.

EVIDENCIA: ruta al archivo con la salida cruda que respalda RESULTADO
— el log, la transcripción del debugger o la captura del profiler tal
cual, no un resumen ni una paráfrasis. Generá la ruta con:

  <skill-dir>/scripts/estado.sh ruta-evidencia <id> <ID_hipotesis>.txt

y pegá esa salida real en el archivo antes de completar este campo.
Sin esto, VEREDICTO queda sin poder verificarse — ver
INSTRUCCIONES.md.

VEREDICTO: "confirmada" si el resultado coincide con la predicción de
esa hipótesis, "descartada" si no. -->

## Condiciones de salida

<!-- No tildes esta casilla vos (agente) — la tilda validar.sh
mecánicamente después de correrlo. Certifica que la entrada de la
hipótesis vigente está completa, nada más — no certifica que toda la
fase esté terminada (eso depende de si el veredicto fue "confirmada" o
si quedan más hipótesis por probar; ver INSTRUCCIONES.md). -->

- [ ] entrada_completa
