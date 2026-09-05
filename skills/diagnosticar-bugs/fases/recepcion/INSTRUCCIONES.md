# Fase 0: Recepción

Antes de arrancar nada nuevo, confirmá si el bug que describe el usuario
ya tiene una investigación abierta en este proyecto (ver ADR 0002 en
`adr/`).

## Flujo

### 1. Listar las investigaciones abiertas

```bash
<skill-dir>/scripts/estado.sh listar
```

Imprime, una por línea, `<id>` y el síntoma registrado — si esa
investigación ya cerró la Fase 2 (Construir bucle de feedback) y lo dejó
documentado; si todavía no, vas a ver `(sin síntoma registrado
todavía)`. Si el proyecto no tiene ninguna investigación abierta, no
imprime nada — eso también es una respuesta válida, no un error.

### 2. Comparar contra lo que describe el usuario (manual, a propósito)

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

## Criterio de cierre

Tenés una decisión explícita y comunicada: **retomar `<id-existente>`** o
**continuar como investigación nueva**. No se avanza sin haber corrido
`estado.sh listar` primero, aunque el resultado haya sido una lista
vacía.
