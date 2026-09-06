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
una tiene que poder refutarse — expresá la predicción con este
formato exacto (el validador lo chequea, busca "si ... entonces"):

  Si <X> es la causa, entonces <cambiar Y> hará desaparecer el bug /
  <cambiar Z> lo empeorará.

HIPOTESIS_4 y HIPOTESIS_5 son opcionales — dejalas vacías si solo
tenés 3. Si el bug es tan acotado que genuinamente no hay 3 causas
plausibles, completá menos y explicá por qué en
JUSTIFICACION_MENOS_DE_3 en vez de inventar hipótesis débiles para
completar el mínimo. -->

HIPOTESIS_1:
HIPOTESIS_2:
HIPOTESIS_3:
HIPOTESIS_4:
HIPOTESIS_5:

## Justificación si hay menos de 3 hipótesis

<!-- Completala solo si generaste menos de 3 (alguna de las tres
primeras quedó vacía): explicá con una frase concreta por qué el bug
no da para más. Si generaste 3 o más, escribí "no aplica". No alcanza
con una respuesta trivial si de verdad tenés menos de 3 — el validador
rechaza justificaciones demasiado cortas. -->

JUSTIFICACION_MENOS_DE_3:

## Condiciones de salida

<!-- No tildes estas casillas vos (agente) — las tilda validar.sh
mecánicamente después de correrlo. Que las hipótesis sean buenas o
estén bien ordenadas NO se verifica acá: eso lo revisa el usuario
cuando le mostrás la lista, en el flujo de INSTRUCCIONES.md. -->

- [ ] cantidad_valida
- [ ] formato_valido
