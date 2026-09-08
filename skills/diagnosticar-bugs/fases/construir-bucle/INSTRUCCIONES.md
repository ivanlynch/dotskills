# Fase: Construir bucle de feedback

## Flujo

### 1. Copiar la plantilla

Ejecutá el siguiente comando para copiar la plantilla — no pisa el
archivo si ya existe (por ejemplo, si estás retomando esta fase
después de un corte de sesión con progreso ya escrito):

```bash
destino="$(<skill-dir>/scripts/estado.sh ruta-fase <id> construir-bucle)"
[ -f "$destino" ] || cp <skill-dir>/fases/construir-bucle/TEMPLATE.md "$destino"
```

### 2. Completar la plantilla

Completá los campos del archivo copiado (`fases/construir-bucle.md`,
dentro de la carpeta del diagnóstico), siguiendo sus comentarios.

### 3. Correr el validador

```bash
<skill-dir>/fases/construir-bucle/scripts/validar.sh "$(<skill-dir>/scripts/estado.sh ruta-fase <id> construir-bucle)"
```

Esto **ejecuta tu `COMANDO` de verdad** (hasta 3 veces, si `TIPO_BUCLE` es
`automatico`) para confirmar mecánicamente las 4 condiciones de salida.

- Imprime `READY` (exit 0) si todo está en orden.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no. Volvé
  al paso 2, ajustá lo que falte según lo que diga el error, y volvé a
  correr el validador. No sigas a la fase siguiente sin `READY`.

### 4. Capa semántica

El validador mecánico **no puede saber** si el rojo que produce el comando
corresponde al síntoma exacto que describió la persona, o a un fallo
parecido pero distinto. Antes de dar la fase por cerrada, releé vos mismo
`SINTOMA_USUARIO` contra `## Corrida real` en el archivo de esta fase y confirmá
explícitamente que coinciden. Si hay ambigüedad, no sigas — volvé al
usuario con la duda puntual usando `/entrevistar` en vez de asumir.

### 5. Acumular y cerrar la fase

Solo después de `READY` **y** de confirmar la capa semántica ejecutá:

```bash
<skill-dir>/scripts/estado.sh acumular <id> construir-bucle "Fase: Construir bucle de feedback"
```

Esto agrega el contenido del archivo de esta fase a `DIAGNOSTICO.md`, el
acumulado persistido del diagnóstico completo (bajo el proyecto actual)
