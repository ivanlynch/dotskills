<!--
Plantilla de la fase "construir bucle de feedback". Copiá este archivo
a fases/construir-bucle.md dentro de la carpeta del diagnóstico y
completá cada campo. No borres los comentarios de instrucciones hasta
terminar — sirven de guía para completar bien.

Los campos en mayúsculas son los que lee scripts/validar.sh. No
cambies sus nombres ni el formato "CAMPO: valor" (una línea).
-->

# Fase — Construir bucle de feedback

## Síntoma reportado por el usuario

<!-- Copiá tal cual el SINTOMA_USUARIO que ya quedó grabado en la
cabecera de DIAGNOSTICO.md (Fase 0, ver ADR 0004) — no lo redactes de
nuevo. Sin interpretar todavía — esto es lo que la Fase 2 va a usar para
confirmar que el bucle detecta ESTE bug y no uno parecido. -->

SINTOMA_USUARIO:

## Método elegido

<!-- Uno de: test_fallido | curl_http | cli_fixture | browser_headless |
replay_trace | arnes_descartable | fuzzing | biseccion_harness |
bucle_diferencial | hitl -->

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

<!-- automatico | hitl — si es hitl, el validador no re-corre el
comando 3 veces (no le pide a la persona que repita los clicks);
en su lugar confía en la corrida que ya hiciste y solo chequea que
los campos de abajo estén completos. -->

TIPO_BUCLE:

## Corrida real (redactá secretos antes de pegar)

<!-- La invocación exacta que ya ejecutaste, y su salida. Es la prueba
de que "ya lo corriste al menos una vez" — no una promesa de que
funcionaría. -->

```
$ 
```

## Ajustes aplicados

<!-- Qué le cambiaste al bucle para hacerlo más rápido, más nítido o
más determinista. "Ninguno" si ya salió bien la primera vez. -->

AJUSTES:

## Condiciones de salida

<!-- No las tildes vos: las tilda scripts/validar.sh
después de re-correr el comando. Dejalas así hasta correr el
validador. -->

- [ ] capaz_de_ponerse_en_rojo
- [ ] determinista
- [ ] rapido
- [ ] ejecutable_sin_supervision
