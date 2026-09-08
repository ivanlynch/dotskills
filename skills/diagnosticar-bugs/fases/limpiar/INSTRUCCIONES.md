# Fase 6: limpiar

## Flujo

### 1. Correr el validador

```bash
<skill-dir>/fases/limpiar/scripts/validar.sh <id>
```

Corré este comando desde la raíz del proyecto (mismo supuesto que el
`COMANDO` de la Fase 1): re-corre ese `COMANDO` y confirma que ya no
reproduce el bug, que la Fase 5 quedó en un estado consistente (test
de regresión o `HALLAZGO`, no los dos ni ninguno), y que no queda
instrumentación `[DEBUG-...]` sin eliminar.

- Imprime `READY` (exit 0) si las 3 condiciones se cumplen.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no.
  Corregí lo que falte y volvé a correrlo.

### 2. Confirmar lo que no se puede mecanizar

El validador no puede saber si un archivo es un prototipo descartable,
ni leer el mensaje de tu commit o PR. Antes de declarar terminado el
trabajo, confirmá vos mismo:

- [ ] Se eliminaron los prototipos descartables (o se movieron a una
      ubicación de debug claramente marcada).
- [ ] La hipótesis que resultó correcta está expresada en el mensaje
      del commit o PR, para que el próximo debugger aprenda de ella.

### 3. Generar el reporte

```bash
<skill-dir>/scripts/generar-reporte.sh <id>
```

Arma `REPORT.md` (junto a `DIAGNOSTICO.md`, en la carpeta de la
investigación) con el problema, el diagnóstico confirmado, la tabla de
hipótesis evaluadas y la corrección aplicada — todo extraído de lo que
ya acumulaste en fases anteriores, sin retipear nada.

Completá vos la sección `## Análisis final` que el script deja en
blanco: un resumen de 3 a 5 líneas de qué pasó, por qué, y qué se
aprendió. Esa síntesis no se puede extraer mecánicamente de los campos
ya escritos — es la única parte de `REPORT.md` que te corresponde
redactar.

## Criterio de cierre

Terminaste cuando el validador dio `READY`, confirmaste los dos ítems
manuales de arriba, y `REPORT.md` quedó generado con `## Análisis
final` completo.
