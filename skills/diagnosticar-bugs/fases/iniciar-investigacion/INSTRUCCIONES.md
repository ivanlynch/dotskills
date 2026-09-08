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

## Si ya tenías una investigación en curso

`estado.sh init` siempre crea una investigación nueva — no verifica si
ya había una abierta para este mismo bug (ver ADR 0005). Si perdiste
de la conversación el `<id>` de una investigación que ya habías
empezado (corte de sesión, contexto comprimido), no la reinicies:
corré `<skill-dir>/scripts/estado.sh listar` para ver las
investigaciones abiertas de este proyecto y retomar la que corresponda
en la fase donde haya quedado.
