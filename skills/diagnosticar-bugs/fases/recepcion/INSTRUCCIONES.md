# Fase 0: Recepción

Antes de arrancar nada nuevo, confirmá si el bug que describe el usuario
ya tiene una investigación abierta en este proyecto (ver ADR 0002 en
`adr/`).

## Flujo

### 1. Listar las investigaciones abiertas

```bash
<skill-dir>/scripts/estado.sh listar
```

Imprime, una por línea, `<id>` y su síntoma. Si el proyecto no tiene
ninguna investigación abierta, no imprime nada — eso también es una
respuesta válida, no un error.

### 2. Clarificar el síntoma

Preguntale a la persona solo lo que falte para tener una frase
comparable — qué pasa, cuándo, esperado vs. real. No es una entrevista
larga: si la descripción ya es precisa, no preguntes nada y seguí
directo al paso 3.

**Si la descripción mezcla más de un síntoma distinto:**

- Evaluá cada uno por separado en el paso 3 (match / ambigüedad / nueva).
- Este flujo trabaja una sola investigación por vez. Si los dos terminan
  siendo nuevos, confirmá con el usuario cuál arrancar primero. No corras
  `init` para el que queda afuera — se retoma en una pasada aparte de
  Recepción cuando llegue su turno.

### 3. Comparar contra la lista (manual, a propósito)

El listado es mecánico; la comparación no — el costo de mezclar dos bugs
distintos bajo el mismo `<id>` es alto, así que esta decisión la hacés
vos, no un matching automático. Releé cada síntoma listado contra el
síntoma clarificado en el paso 2:

- **Coincidencia clara** → es la misma investigación. Anotá su `<id>` y
  saltá directo a retomarla en la fase que corresponda — no corras
  `estado.sh init`, ni pases por la Fase 1 (Iniciar investigación).
- **Ambigüedad** (se parece, pero no estás seguro) → no asumas. Mostrale
  al usuario las opciones y preguntale si es la misma investigación o una
  nueva.
- **Sin coincidencia** (o la lista vino vacía) → seguí a la Fase 1, es una
  investigación nueva.

**Si la lista vino vacía pero debería haber algo:** el usuario está
seguro de que esto ya se investigó, puede ser que `origin` haya cambiado
(rename del repo, migración de host) — las investigaciones viejas quedan
bajo el identificador anterior y `listar` no las ve. Antes de asumir que
es nueva, revisá `estado.sh migrar <identificador-viejo>` (identificador
tal como quedó grabado en la cabecera "Proyecto:" de un `DIAGNOSTICO.md`
viejo) y volvé a correr `listar`.

## Criterio de cierre

Tenés una decisión explícita y comunicada: **retomar `<id-existente>`** o
**continuar como investigación nueva**. No se avanza sin haber corrido
`estado.sh listar` primero, aunque el resultado haya sido una lista
vacía.
