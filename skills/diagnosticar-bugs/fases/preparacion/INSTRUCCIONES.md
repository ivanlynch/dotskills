# Fase 0: Preparación

Corré esto desde el proyecto donde está el bug (el script identifica el
proyecto por su remoto git, para no mezclar diagnósticos de repos
distintos):

```bash
<skill-dir>/scripts/estado.sh init <id>
```

`<id>` es un slug corto derivado del bug (minúsculas, guiones — ej.
`export-timeout-500`). El comando es determinista: la ruta depende solo
del proyecto (hash del remoto git) y de `<id>`. Si esa carpeta ya existe,
el comando no la toca y solo imprime la ruta — cerrá la fase ahí mismo,
sin preparar nada más. Si no existe, la crea (con `fases/` y
`DIAGNOSTICO.md` vacío adentro) y también imprime la ruta.

## Criterio de cierre

El comando imprimió una ruta de carpeta, haya existido antes o la haya
creado recién.
