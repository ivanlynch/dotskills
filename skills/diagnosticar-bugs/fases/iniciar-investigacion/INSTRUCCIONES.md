# Fase 0: Iniciar investigación

Si la descripción del bug ya es precisa (qué pasa, cuándo, esperado vs.
real), seguí directo al paso siguiente. Si no, usá
[`/entrevistar`](../../../entrevistar/SKILL.md) hasta tener un síntoma
claro.

Reemplazá `<sintoma>` por ese texto y corré, desde el proyecto donde está
el bug:

```bash
<skill-dir>/scripts/estado.sh init "<sintoma>"
```

## Criterio de cierre

El comando devolvió un `<id>` (ej. `INV007`).
