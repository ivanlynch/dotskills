# Fase 1: Iniciar investigación

Solo llegás acá si la Fase 0 (Recepción) confirmó que esto es una
investigación **nueva** — no una que ya estaba abierta.

Corré esto desde el proyecto donde está el bug (el script identifica el
proyecto por su remoto git, para no mezclar diagnósticos de repos
distintos), pasándole el síntoma ya clarificado en el paso 2 de Fase 0:

```bash
<skill-dir>/scripts/estado.sh init "<sintoma-clarificado>"
```

El comando no recibe un id: lo genera él mismo, incremental y por
proyecto (`INV001`, `INV002`, ...), usando un contador persistente con
lock para que dos investigaciones que arrancan casi al mismo tiempo no
colisionen (ver ADR 0001 en `adr/`). Cada llamada crea una investigación
nueva — nunca actualiza una existente; esa responsabilidad, si hiciera
falta, es de la Fase 0 al retomar un match (ver ADR 0002).

El síntoma queda grabado como `SINTOMA_USUARIO` en `DIAGNOSTICO.md` desde
este mismo momento — no recién al cerrar la Fase 2 (Construir bucle de
feedback, ver ADR 0004). Así, si esta investigación queda inconclusa,
`estado.sh listar` en la próxima Recepción va a tener algo real con qué
comparar.

`init` crea la carpeta (con `fases/` y `DIAGNOSTICO.md` con su cabecera y
el síntoma adentro) e imprime el id generado.

## Criterio de cierre

El comando imprimió el id generado (ej. `INV007`). Guardalo — es lo que
vas a pasar como `<id>` en todas las fases siguientes.
