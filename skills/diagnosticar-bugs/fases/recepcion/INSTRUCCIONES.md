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

La comparación del paso 3 depende de tener un síntoma claro — uno vago
compara mal contra lo que ya está listado. Si lo que describió la
persona ya es preciso (qué pasa, cuándo, esperado vs. real), no le
preguntes nada por preguntar: seguí directo al paso 3. Si es vago, mezcla
más de un síntoma distinto, o falta esperado-vs-real, preguntale lo
puntual que falte antes de seguir — no una entrevista larga, lo mínimo
para tener una frase comparable. Si identificás dos síntomas distintos en
una sola descripción, no los mezcles bajo una sola decisión: evaluá cada
uno por separado en el paso 3 (match/ambigüedad/nueva). Este flujo
trabaja una sola investigación por vez — si los dos terminan siendo
nuevos, confirmá con el usuario con cuál arrancar y dejá el otro sin
crear (no corras `init` para el que queda afuera); se retoma como una
pasada aparte de Recepción cuando llegue su turno.

### 3. Comparar contra lo que describe el usuario (manual, a propósito)

**El listado es mecánico; la comparación no.** Este script no decide por
vos — lo mismo que la capa semántica de la Fase 2 (ver
`fases/construir-bucle/INSTRUCCIONES.md`), construir acá un matching
automático es peor que dejarlo explícito: el costo de mezclar dos bugs
distintos bajo el mismo `<id>` es alto. Releé cada síntoma listado contra
lo que la persona te describió ahora:

- **Coincidencia clara** → es la misma investigación. Anotá su `<id>` y
  saltá directo a retomarla en la fase que corresponda — no vuelvas a
  correr `estado.sh init`, ni pases por la Fase 1 (Iniciar investigación).
- **Ambigüedad** (se parece, pero no estás seguro) → no asumas. Mostrale
  al usuario las opciones y preguntale si es la misma investigación o una
  nueva.
- **Sin coincidencia** (o la lista vino vacía) → seguí a la Fase 1, es una
  investigación nueva.

Si la lista vino vacía pero el usuario está seguro de que esto ya se
investigó antes, puede ser que `origin` haya cambiado (rename del repo,
migración de host): las investigaciones viejas quedan bajo el
identificador anterior y `listar` no las ve. Antes de asumir que es
nueva, revisá si corresponde `estado.sh migrar <identificador-viejo>`
(identificador tal como quedó grabado en la cabecera "Proyecto:" de un
`DIAGNOSTICO.md` viejo) y volvé a correr `listar`.

## Criterio de cierre

Tenés una decisión explícita y comunicada: **retomar `<id-existente>`** o
**continuar como investigación nueva**. No se avanza sin haber corrido
`estado.sh listar` primero, aunque el resultado haya sido una lista
vacía.
