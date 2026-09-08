# Fase 5: corregir y agregar el test de regresión

Antes de tocar código, releé la hipótesis **confirmada** de la Fase 4
(el registro con `VEREDICTO: confirmada` en `DIAGNOSTICO.md`, con su
`SONDEO` y `RESULTADO`) — la corrección tiene que atacar esa causa
puntual, no una intuición nueva.

Copiá la plantilla de esta fase:

```bash
cp <skill-dir>/fases/corregir-testear/TEMPLATE.md \
   "$(<skill-dir>/scripts/estado.sh ruta-fase <id> corregir-testear)"
```

## ¿Se puede testear en el lugar correcto?

Escribí el test de regresión antes de la corrección, pero solo si podés
escribirlo en el lugar del código donde reproduce el **patrón real
del bug** tal como ocurre en producción — no en un lugar más
superficial que dé falsa sensación de seguridad. Por ejemplo: un test
de un único caller cuando el bug necesita varios callers, o un test
unitario que no puede reproducir la cadena de llamadas que lo
disparó.

**Si no lo hay:** completá `SE_PUEDE_TESTEAR: no` y `HALLAZGO` en la
plantilla — lo que falta es la forma de *testear* el patrón real del
bug, no de corregirlo. Igual vas a aplicar la corrección, solo que sin
test de regresión. Andá directo a "Aplicar y verificar".

**Si lo hay:** completá `SE_PUEDE_TESTEAR: sí` y `TEST_DE_REGRESION`
con su ubicación, y escribilo **antes de la corrección**:

1. Convertí la reproducción minimizada (`COMANDO_MINIMIZADO` de la
   Fase 2) en un test fallido ahí.
2. Observá cómo falla.

## Aplicar y verificar

3. Aplicá la corrección — la que ataca la causa confirmada, no un
   parche alrededor del síntoma.
4. Si escribiste un test de regresión: observá cómo pasa. Si no pasa
   al primer intento, no sigas — ajustá la corrección y repetí este
   paso.
5. Volvé a ejecutar el `COMANDO` original de la Fase 1 (sin
   minimizar) contra el escenario completo. Si sigue en rojo, la
   corrección no alcanza — volvé al paso 3.
6. Completá `CORRECCION` en la plantilla con un resumen de qué cambió
   y por qué ataca la causa confirmada.

## Acumular y cerrar la fase

```bash
<skill-dir>/scripts/estado.sh acumular <id> corregir-testear "Fase: Corregir y testear"
```

## Criterio de cierre

Terminaste cuando la corrección está aplicada, el `COMANDO` original
de la Fase 1 da verde, y se corrió `acumular` — con test de regresión
si había un lugar correcto para escribirlo, o con `HALLAZGO`
documentado si no lo había.
