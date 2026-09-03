<!--
Plantilla de la fase "construir bucle de feedback". Copiá este archivo
a fases/construir-bucle.md dentro de la carpeta del diagnóstico y
completá cada campo. No borres los comentarios de instrucciones hasta
terminar — sirven de guía para completar bien.

Los campos en mayúsculas son los que lee scripts/validar.sh. No
cambies sus nombres ni el formato "CAMPO: valor" (una línea).
-->

# Fase 1 — Construir bucle de feedback

## Síntoma reportado por el usuario

<!-- Copiá o parafraseá exactamente lo que la persona describió. Sin
interpretar todavía — esto es lo que la Fase 2 va a usar para confirmar
que el bucle detecta ESTE bug y no uno parecido. -->

SINTOMA_USUARIO:

## Método elegido

<!-- Uno de: test_fallido | curl_http | cli_fixture | browser_headless |
replay_trace | arnes_descartable | fuzzing | biseccion_harness |
bucle_diferencial | hitl -->

METODO:

## Comando

<!-- Un solo comando, ejecutable tal cual desde la raíz del proyecto.
El validador lo va a correr de verdad — no describas lo que haría,
pegá el comando real. -->

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
