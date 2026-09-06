<!--
Plantilla de la fase "reproducir y minimizar".

Instrucciones:
1. Leé los comentarios — son una guía de cómo completar cada sección.
2. Completá los campos, respetando este formato: los campos en
mayúsculas los lee scripts/validar.sh con un grep línea por línea (no
interpreta variaciones), así que mantené el nombre exacto y el valor
completo en una única línea física, pegado después de los dos puntos
("CAMPO: valor"). Ni siquiera una continuación de línea con "\"
funciona — grep no une líneas.

-->

# Fase: Reproducir y minimizar

## Síntoma reportado por el usuario

<!-- Ya viene completo: lo precargó scripts/iniciar.sh copiándolo de
DIAGNOSTICO.md. No lo edites — más abajo, la capa semántica lo compara
textualmente contra la corrida real para confirmar que seguís
reproduciendo el mismo bug. -->

SINTOMA_USUARIO:

## Comando minimizado

<!-- Ya viene completo con el COMANDO que cerró la Fase 1 — lo
precargó scripts/iniciar.sh. Andá recortando este valor a mano: sacá
entradas, llamadas, configuración, datos y pasos de a uno, corriendo
de nuevo el comando después de cada recorte, hasta que sacar
cualquier cosa más lo pase a verde. -->

COMANDO_MINIMIZADO:

## Recortes aplicados

<!-- Qué le sacaste al comando de la Fase 1 para llegar a esta versión
mínima — por ejemplo "saqué los campos opcionales del payload" o
"reduje el dataset de 500 a 3 filas". Escribí "ninguno" si el comando
de la Fase 1 ya era mínimo. No podés dejarlo vacío. -->

RECORTES:

## Confirmación de mínimo

<!-- Nadie puede automatizar esto — depende del código puntual del
bug. Confirmá con una frase concreta que probaste sacar cada elemento
que quedó y que sacar cualquiera hace que el comando pase a verde. Por
ejemplo: "probé sacar cada campo restante del payload uno por uno; en
los tres casos el comando dejó de reproducir el bug." No alcanza con
"sí" — el validador rechaza confirmaciones demasiado cortas. -->

ES_MINIMO:

## Corrida real

<!-- Pegá la invocación exacta del COMANDO_MINIMIZADO ya recortado,
con su salida real — es la prueba de que ya lo corriste al menos una
vez, no una promesa de que funcionaría. -->

```
$ 
```

## Condiciones de salida

<!-- No tildes estas casillas vos (agente) — las tilda validar.sh
mecánicamente después de correrlo. Que sea mínimo NO está acá: eso lo
declarás arriba, en ES_MINIMO, porque ningún script puede verificarlo
por vos. -->

- [ ] reproduce_el_bug
- [ ] determinista
