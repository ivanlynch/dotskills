# Fase 3: formular hipótesis

## Flujo

### 1. Iniciar la fase

```bash
<skill-dir>/fases/formular-hipotesis/scripts/iniciar.sh <id>
```

Copia la plantilla, completa `SINTOMA_USUARIO` automáticamente (usando
el valor ya grabado en `DIAGNOSTICO.md`), y agrega 5 campos de
hipótesis en blanco con IDs nuevos que nunca se repiten en toda la
investigación. Si esta es una vuelta posterior porque la Fase 4 agotó
la ronda anterior sin confirmar ninguna, los IDs arrancan después del
último usado (ej. `H06` en vez de `H01`) — no hace falta calcular nada
a mano.

### 2. Completar la plantilla

Completá los campos del archivo copiado (`fases/formular-hipotesis.md`,
dentro de la carpeta del diagnóstico), siguiendo sus comentarios.

### 3. Correr el validador

```bash
<skill-dir>/fases/formular-hipotesis/scripts/validar.sh "$(<skill-dir>/scripts/estado.sh ruta-fase <id> formular-hipotesis)"
```

A diferencia de las Fases 1 y 2, acá no hay ningún comando que se
ejecute de verdad — formular hipótesis es puro razonamiento, sin señal
roja/verde. Esto solo confirma que hay entre 1 y 5 hipótesis
completas, cada una con el formato refutable exigido, y que si hay
menos de 3 quedó explícitamente justificado por qué.

- Imprime `READY` (exit 0) si todo está en orden.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no. Volvé
  al paso 2, ajustá lo que falte según lo que diga el error, y volvé a
  correr el validador. No sigas a la fase siguiente sin `READY`.

### 4. Mostrar la lista al usuario

**Mostrale la lista ordenada al usuario antes de probarla.** El
usuario puede aportar conocimiento del dominio y reordenarla de
inmediato («acabamos de desplegar un cambio relacionado con la #3») o
saber qué hipótesis ya descartó. Es un punto de control barato y
ahorra mucho tiempo.

Este paso **no bloquea el avance**: si el usuario no responde, seguí
con tu ordenamiento — a diferencia de la capa semántica de las Fases 1
y 2, acá no hace falta su confirmación explícita para acumular.

### 5. Acumular y cerrar la fase

```bash
<skill-dir>/scripts/estado.sh acumular-hipotesis <id>
```

A diferencia de las demás fases, **esta fase sí puede cerrarse más de
una vez** en la misma investigación (una tanda de hipótesis es un
resultado válido en sí mismo, aunque después ninguna resulte ser la
causa). Por eso no usa el `acumular` genérico: `acumular-hipotesis` es
específico de esta fase — si es la primera vez, crea la sección
`## Fase: Formular hipótesis`; si ya existe (porque hubo una vuelta
anterior), **fusiona** los registros nuevos ahí adentro y actualiza
`JUSTIFICACION_MENOS_DE_3`, en vez de crear una sección duplicada con
todo el comentario de la plantilla repetido de nuevo.
