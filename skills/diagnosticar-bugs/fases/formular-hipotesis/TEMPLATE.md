<!--
Plantilla de la fase "formular hipótesis".

Instrucciones:
1. Leé los comentarios — son una guía de cómo completar cada sección.
2. Completá los campos, respetando este formato: los campos en
mayúsculas los lee scripts/validar.sh con un grep línea por línea (no
interpreta variaciones), así que mantené el nombre exacto y el valor
completo en una única línea física, pegado después de los dos puntos
("CAMPO: valor"). Ni siquiera una continuación de línea con "\"
funciona — grep no une líneas.

-->

# Fase: Formular hipótesis

## Síntoma reportado por el usuario

<!-- Ya viene completo: lo precargó scripts/iniciar.sh copiándolo de
DIAGNOSTICO.md. No lo edites — es solo contexto para quien lea esta
fase después. -->

SINTOMA_USUARIO:

## Hipótesis

<!-- Generá 3 a 5 hipótesis ordenadas, la más probable primero.
Generar una sola hace que te ancles en la primera idea plausible. Cada
una es un registro de dos campos, "ID:" e "HIPOTESIS:", separado del
siguiente por una línea en blanco:

  ID: H01
  HIPOTESIS: Si <X> es la causa, entonces <cambiar Y> hará desaparecer
  el bug / <cambiar Z> lo empeorará.

Los registros que aparecen abajo ya vienen con su "ID:" agregado por
scripts/iniciar.sh, con IDs que nunca se repiten en toda la
investigación — si esta es una segunda vuelta porque la Fase 4 agotó
la ronda anterior, van a arrancar más arriba de H05 (ej. H06). No
edites el "ID:" de ningún registro; completá solo su "HIPOTESIS:".
Podés dejar sin completar los registros que no uses (el mínimo es 3,
salvo que justifiques menos abajo). La predicción tiene que poder
refutarse (el validador la chequea, busca "si ... entonces" en el
texto). Si es una segunda vuelta, revisá primero
fases/instrumentar.md (todavía sin acumular, si existe) para ver qué
se descartó y por qué — no repitas esas hipótesis. -->

## Justificación si hay menos de 3 hipótesis

<!-- Completala solo si generaste menos de 3. Explicá con una frase
concreta por qué el bug no da para más. Si generaste 3 o más, escribí
"no aplica". No alcanza con una respuesta trivial si de verdad tenés
menos de 3 — el validador rechaza justificaciones demasiado cortas. -->

JUSTIFICACION_MENOS_DE_3:

## Condiciones de salida

<!-- No tildes estas casillas vos (agente) — las tilda validar.sh
mecánicamente después de correrlo. Que las hipótesis sean buenas o
estén bien ordenadas NO se verifica acá: eso lo revisa el usuario
cuando le mostrás la lista, en el flujo de INSTRUCCIONES.md. -->

- [ ] cantidad_valida
- [ ] formato_valido
