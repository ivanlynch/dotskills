# Fase 1: Iniciar investigación

Solo llegás acá si la Fase 0 (Recepción) confirmó que esto es una
investigación **nueva** — no una que ya estaba abierta.

Corré esto desde el proyecto donde está el bug (el script identifica el
proyecto por su remoto git, para no mezclar diagnósticos de repos
distintos):

```bash
<skill-dir>/scripts/estado.sh init
```

El comando no recibe un id: lo genera él mismo, incremental y por
proyecto (`INV001`, `INV002`, ...), usando un contador persistente con
lock para que dos investigaciones que arrancan casi al mismo tiempo no
colisionen (ver ADR 0001 en `adr/`). Cada llamada crea una investigación
nueva — nunca actualiza una existente; esa responsabilidad, si hiciera
falta, es de la Fase 0 al retomar un match (ver ADR 0002).

`init` crea la carpeta (con `fases/` y `DIAGNOSTICO.md` vacío adentro) e
imprime el id generado.

## Criterio de cierre

El comando imprimió el id generado (ej. `INV007`). Guardalo — es lo que
vas a pasar como `<id>` en todas las fases siguientes.
