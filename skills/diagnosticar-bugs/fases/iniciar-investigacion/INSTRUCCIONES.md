# Fase 1: Iniciar investigación

Corré esto desde el proyecto donde está el bug (el script identifica el
proyecto por su remoto git, para no mezclar diagnósticos de repos
distintos), pasándole el síntoma de Fase 0:

```bash
<skill-dir>/scripts/estado.sh init "<sintoma>"
```

El comando no recibe un id: lo genera él mismo, incremental y por
proyecto (`INV001`, `INV002`, ...), usando un contador persistente con
lock para que dos investigaciones que arrancan casi al mismo tiempo no
colisionen (ver ADR 0001 en `adr/`).

El síntoma queda grabado como `SINTOMA_USUARIO` en la cabecera de
`DIAGNOSTICO.md` (obligatorio, ver ADR 0004).

`init` crea la carpeta (con `fases/` y `DIAGNOSTICO.md` con su cabecera y
el síntoma adentro) e imprime el id generado.

## Criterio de cierre

El comando imprimió el id generado (ej. `INV007`). Guardalo — es lo que
vas a pasar como `<id>` en todas las fases siguientes.
