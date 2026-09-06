# Fase 3: formular hipótesis

## Flujo

### 1. Iniciar la fase

```bash
<skill-dir>/fases/formular-hipotesis/scripts/iniciar.sh <id>
```

Copia la plantilla y precarga `SINTOMA_USUARIO` con el valor que ya
quedó en `DIAGNOSTICO.md` — no hace falta que lo copies vos.

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
<skill-dir>/scripts/estado.sh acumular <id> formular-hipotesis "Fase: Formular hipótesis"
```

Esto agrega el contenido del archivo de esta fase a `DIAGNOSTICO.md`,
el acumulado persistido del diagnóstico completo (bajo el proyecto
actual) — ver `../../STATE_MACHINE.md` sobre por qué este estado
sobrevive a la sesión y a la conversación. La Fase 4 (Instrumentar)
depende de que esta lista quede acumulada acá: cada sondeo tiene que
corresponder a una hipótesis puntual de esta fase.
