# Fase 4: instrumentar

## Flujo

### 1. Iniciar o continuar la fase

```bash
<skill-dir>/fases/instrumentar/scripts/iniciar.sh <id>
```

La primera vez crea el archivo y precarga `SINTOMA_USUARIO`. En
cualquier corrida (primera o no), agrega un registro
(`ID:`/`SONDEO:`/`RESULTADO:`/`EVIDENCIA:`/`VEREDICTO:`) por cada
hipótesis de la Fase 3 que todavía no tenga uno acá, sin pisar los que
ya existen — así una ronda nueva de hipótesis se suma sin perder el
trabajo ya hecho.

### 2. Probar la hipótesis vigente

La vigente es la de menor ID que todavía no tiene `VEREDICTO`
puesto — no hay ningún campo que la señale, es el primer registro
vacío que encontrás bajando por el archivo. Completá su
`SONDEO`/`RESULTADO`, siguiendo los comentarios de la plantilla —
ahí está la técnica de instrumentación.

Antes de completar `VEREDICTO`, guardá la salida cruda del sondeo (el
log, la transcripción del debugger, la captura del profiler — tal
cual, no un resumen) en:

```bash
<skill-dir>/scripts/estado.sh ruta-evidencia <id> <ID_hipotesis>.txt
```

y completá `EVIDENCIA` con esa ruta. Recién con eso elegí `confirmada`
o `descartada` para `VEREDICTO`, siguiendo el criterio de la
plantilla — sin evidencia cruda guardada, el validador no deja avanzar
(paso 3).

### 3. Correr el validador

```bash
<skill-dir>/fases/instrumentar/scripts/validar.sh "$(<skill-dir>/scripts/estado.sh ruta-fase <id> instrumentar)"
```

Esto valida **solo la entrada vigente**, no toda la fase — Instrumentar
es un loop, así que puede pasar por acá una vez por cada hipótesis que
se prueba. `READY` significa específicamente que encontraste la causa
(`confirmada`) — no que una entrada individual quedó bien documentada.
Descartar una hipótesis, por más completa que esté, nunca da `READY`
por sí solo: el validador pasa directo a chequear la siguiente vigente
(o el agotamiento, si no queda ninguna).

- **`READY`** (exit 0) → una hipótesis quedó `confirmada`. Andá al paso 4.
- **`NOT_READY`** (exit 1), con el motivo exacto por stderr:
  - Si el motivo es que falta `SONDEO`/`RESULTADO`/`EVIDENCIA`/
    `VEREDICTO` de una hipótesis puntual, o que `EVIDENCIA` apunta a un
    archivo vacío o inexistente: completá ese registro (paso 2) y
    volvé a correr el validador.
  - Si el motivo es que **todas las hipótesis conocidas ya tienen
    veredicto y ninguna es `confirmada`** (agotamiento): **no inventes
    sondeos sueltos sin fundamento**. Volvé a la Fase 3 para generar
    una ronda nueva. No acumules esta fase todavía — no hay nada
    resuelto que cerrar. El archivo sigue en disco con todo lo ya
    probado; cuando vuelvas acá después de la ronda nueva, el paso 1
    va a agregar los registros de las hipótesis nuevas sin tocar los
    que ya tenés.

### 4. Acumular y cerrar la fase

Solo cuando el validador dio `READY`:

```bash
<skill-dir>/scripts/estado.sh acumular <id> instrumentar "Fase: Instrumentar"
```

A diferencia de Fase 3, esta fase **acumula una única vez** — recién
cuando se confirma una hipótesis, no en cada vuelta del loop. Cerrar
una ronda que no encontró nada no tendría ningún resultado que
declarar resuelto.

Esto agrega el contenido del archivo de esta fase a `DIAGNOSTICO.md`
(incluye el historial completo de hipótesis descartadas y la que se
confirmó) — ver `../../STATE_MACHINE.md` sobre por qué este estado
sobrevive a la sesión y a la conversación.
