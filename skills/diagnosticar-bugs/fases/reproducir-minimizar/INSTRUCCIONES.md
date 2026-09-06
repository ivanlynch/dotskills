# Fase 2: reproducir y minimizar

## Flujo

### 1. Iniciar la fase

```bash
<skill-dir>/fases/reproducir-minimizar/scripts/iniciar.sh <id>
```

Copia la plantilla y completa `SINTOMA_USUARIO` y `COMANDO_MINIMIZADO`
automáticamente, usando los valores ya grabados en `DIAGNOSTICO.md`
(Fase 0 y Fase 1 acumulada). No hace falta escribir esos valores a
mano.

### 2. Minimizar y completar la plantilla

Completá los campos del archivo copiado (`fases/reproducir-minimizar.md`,
dentro de la carpeta del diagnóstico), siguiendo sus comentarios.

### 3. Correr el validador

```bash
<skill-dir>/fases/reproducir-minimizar/scripts/validar.sh "$(<skill-dir>/scripts/estado.sh ruta-fase <id> reproducir-minimizar)"
```

Esto **ejecuta tu `COMANDO_MINIMIZADO` de verdad** (3 veces) para
confirmar mecánicamente que sigue reproduciendo el bug y sigue siendo
determinista — no confía en tu palabra de que ya lo probaste.

- Imprime `READY` (exit 0) si todo está en orden.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no. Volvé
  al paso 2, ajustá lo que falte según lo que diga el error, y volvé a
  correr el validador. No sigas a la fase siguiente sin `READY`.

### 4. Capa semántica

El validador mecánico **no puede saber** si el fallo que reproduce
`COMANDO_MINIMIZADO` corresponde al síntoma exacto que describió la
persona, ni si el escenario es realmente mínimo — eso ya lo declaraste
en `ES_MINIMO`, con tu propio criterio del código. Antes de dar la fase
por cerrada, releé vos mismo `SINTOMA_USUARIO` contra `## Corrida real`
y confirmá explícitamente que coinciden. Si hay ambigüedad, no sigas —
volvé al usuario con la duda puntual usando `/entrevistar` en vez de
asumir.

### 5. Acumular y cerrar la fase

Solo después de `READY` **y** de confirmar la capa semántica ejecutá:

```bash
<skill-dir>/scripts/estado.sh acumular <id> reproducir-minimizar "Fase: Reproducir y minimizar"
```
