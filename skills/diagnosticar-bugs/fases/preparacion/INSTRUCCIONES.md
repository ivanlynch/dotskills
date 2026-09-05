# Fase 0: Preparación

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
nueva — no es idempotente. Para retomar una investigación ya abierta, no
vuelvas a correr `init`: usá el id que ya te devolvió antes con `estado.sh
dir <id>`, `ruta-fase`, etc.

`init` crea la carpeta (con `fases/` y `DIAGNOSTICO.md` vacío adentro) e
imprime el id generado.

## Criterio de cierre

El comando imprimió el id generado (ej. `INV007`). Guardalo — es lo que
vas a pasar como `<id>` en todas las fases siguientes.
