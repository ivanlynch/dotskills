<!--
Plantilla de la fase "construir bucle de feedback".

Instrucciones:
1. Leé los comentarios — son una guía de cómo completar cada sección.
2. Completá los campos, respetando este formato: los campos en
mayúsculas los lee scripts/validar.sh con un grep línea por línea (no
interpreta variaciones), así que mantené el nombre exacto y el valor
completo en una única línea física, pegado después de los dos puntos
("CAMPO: valor"). Ni siquiera una continuación de línea con "\"
funciona — grep no une líneas.

-->

# Fase: Construir bucle de feedback

<!-- Esta es la fase más importante de todo el diagnóstico: construí un
comando que se pone en rojo con este bug puntual y en verde cuando esté
arreglado. Las fases siguientes se reducen a correr ese mismo comando
una y otra vez, sin criterio nuevo. Invertí más tiempo acá que en
cualquier otra fase — si el método que elegiste no funciona, probá otro
de la lista antes de rendirte. -->

## Síntoma reportado por el usuario

<!-- Copiá tal cual el SINTOMA_USUARIO de la cabecera de DIAGNOSTICO.md
— no lo reinterpretes: la Fase 2 lo compara textualmente contra la
corrida real para confirmar que el bucle detecta este bug. -->

SINTOMA_USUARIO:

## Método elegido

<!-- Elegí el que mejor encaje con tu bug — usá criterio, no los
pruebes todos en orden. Ante dos opciones igual de viables, preferí
la que aparece primero en esta lista (van de más simple/barata a más
compleja):

1. test_fallido: test fallido en cualquier frontera que alcance el
   bug (unitario, integración o e2e).
2. curl_http: script curl / HTTP contra un servidor de desarrollo en
   ejecución.
3. cli_fixture: invocación de CLI con una entrada fixture, comparando
   stdout con un snapshot conocido como correcto.
4. browser_headless: script de navegador headless (Playwright /
   Puppeteer) que conduzca la UI y haga aserciones sobre DOM, consola
   o red.
5. replay_trace: reproducción de un trace capturado. Guardá en disco
   una petición de red, payload o registro de eventos real, y
   reproducilo a través del código de forma aislada.
6. arnes_descartable: levantá el subconjunto mínimo del sistema —un
   servicio y dependencias simuladas— que ejercite el camino del bug
   con una sola llamada de función.
7. fuzzing: bucle de propiedades / fuzzing. Si el bug produce una
   salida incorrecta solo a veces, ejecutá entradas aleatorias y
   buscá el modo de falla.
8. biseccion_harness: si el bug apareció entre dos estados conocidos
   —commit, dataset o versión—, automatizá «iniciar en el estado X y
   comprobar» para poder usar `git bisect run`.
9. bucle_diferencial: ejecutá la misma entrada con la versión
   anterior y la nueva —o con dos configuraciones— y compará las
   salidas.
10. hitl: script bash HITL. Último recurso — ver el criterio en
    TIPO_BUCLE más abajo. -->

METODO:

## Comando

<!-- Un solo comando, ejecutable tal cual desde la raíz del proyecto.
El validador lo va a correr de verdad (3 veces, si TIPO_BUCLE es
automatico) y se fija únicamente en su exit code: 0 = no hay bug
(verde), cualquier otro número = hay bug (rojo). No mira nada de lo
que el comando imprime — esa salida se descarta.

Esto importa si tu bug es "el programa termina bien pero imprime algo
incorrecto" (no crashea, no devuelve un exit code distinto de 0 por sí
solo). En ese caso, COMANDO no puede ser el programa pelado — tiene
que ser un chequeo que vos armás, cuyo propio exit code sea el
veredicto:

- Comparar contra una salida correcta ya guardada:

    diff <(mi-cli exportar) salida-esperada.txt

  diff ya sale con 0 si son iguales (verde) y con 1 si son distintos
  (rojo) — no hace falta nada más.

- Buscar el texto de un error o un valor incorrecto puntual:

    ! mi-cli exportar | grep -q "Total: 41"

  grep -q sale con 0 si ENCUENTRA "Total: 41" (el valor malo). El `!`
  adelante da vuelta ese resultado: el conjunto sale con 0 (verde)
  cuando el valor malo NO aparece, y con 1 (rojo) cuando sí aparece.

Si en cambio tu bug ya crashea o devuelve un exit code distinto de 0
por su cuenta (la mayoría de los tests fallidos, errores de red,
excepciones no capturadas), no hace falta nada de esto: pegá el
comando tal cual. -->

COMANDO:

## Tipo de bucle

<!-- Uno de: automatico | hitl.

Por defecto es automatico. Es hitl únicamente cuando probaste los
primeros 9 métodos de METODO y ninguno te sirvió — es el método #10,
el último recurso, no una opción más entre las otras.

Si es hitl, el validador no re-corre el comando 3 veces (no le pide a
la persona que repita los clicks); en su lugar confía en la corrida
que ya hiciste y solo chequea que los campos de abajo estén
completos. Por eso, si llegás a hitl: copiá y adaptá
<skill-dir>/scripts/hitl-loop.template.sh, corré esa sesión con la
persona, y pegá la corrida real bajo "Corrida real" (más abajo) ANTES
de correr el validador — necesita esa evidencia ya escrita. -->

TIPO_BUCLE:

## Ajustes aplicados

<!-- Completalo antes de correr el validador, durante tu propia
prueba manual: corré el COMANDO a mano y, si sale lento, flaky o el
síntoma que detecta es ambiguo, ajustalo (fijá un seed, mockeá la
red, cacheá un setup) hasta que ande bien. Documentá acá qué le
cambiaste para llegar a esa versión — o escribí "ninguno" si funcionó
bien de entrada. No podés dejarlo vacío. -->

AJUSTES:

## Corrida real

<!-- Pegá, ya con los ajustes aplicados, la invocación exacta que
ejecutaste y su salida real — es la prueba de que ya lo corriste al
menos una vez, no una promesa de que funcionaría. Ojo: validar.sh solo
la chequea mecánicamente en modo hitl; en automatico no la lee (re-corre
COMANDO él mismo), pero completala igual como evidencia. -->

```
$ 
```

## Condiciones de salida

<!-- No tildes estas casillas vos (agente) — las tilda validar.sh
mecánicamente después de correrlo. -->

- [ ] capaz_de_ponerse_en_rojo
- [ ] determinista
- [ ] rapido
- [ ] ejecutable_sin_supervision
