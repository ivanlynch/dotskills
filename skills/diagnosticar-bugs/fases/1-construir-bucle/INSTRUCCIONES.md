<!--
Instrucciones internas de la Fase 1 de diagnosticar-bugs. No es un
SKILL.md a propósito: Codex descubre SKILL.md de forma recursiva en
todo el árbol symlinkeado, y esta fase no tiene sentido invocada por
su cuenta — solo como parte del flujo de diagnosticar-bugs.
-->

# Fase 1 — Construir bucle de feedback

Esta fase reemplaza a la Fase 1 de `SKILL.md` con una versión mecanizada:
en vez de confiar en que vos (el agente) evaluaste bien las 4 condiciones
de salida, un script las re-verifica corriendo el comando de verdad.

## Flujo

### 1. Inicializar el diagnóstico

Si es la primera fase de un diagnóstico nuevo:

```bash
<skill-dir>/scripts/diagnostico_state.sh init <id>
```

`<id>` es un slug corto derivado del bug (minúsculas, guiones — ej.
`export-timeout-500`). El comando imprime la ruta de la carpeta creada.

### 2. Copiar la plantilla y completarla

```bash
cp <skill-dir>/fases/1-construir-bucle/template.md \
   "$(<skill-dir>/scripts/diagnostico_state.sh ruta-fase <id> 1-construir-bucle)"
```

Completá cada campo siguiendo la Fase 1 de `SKILL.md` (mismo criterio: probá
los métodos en el orden de esa lista, sé agresivo y creativo, no te rindas).
**No tildes las casillas de "condiciones de salida" vos mismo** — eso lo
hace el validador en el paso siguiente.

### 3. Correr la capa mecánica

```bash
<skill-dir>/fases/1-construir-bucle/scripts/validar_estructura.sh "$(<skill-dir>/scripts/diagnostico_state.sh ruta-fase <id> 1-construir-bucle)"
```

- Imprime `READY` (exit 0) si el comando declarado, corrido de verdad 3
  veces, cumple las 4 condiciones.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no. Volvé
  al paso 2, ajustá el `COMANDO` (o los campos que falten) según lo que
  diga el error, y volvé a correr el validador. No sigas a la Fase 2 sin
  `READY`.

Si el bug necesita intervención humana (`TIPO_BUCLE: hitl`), copiá y
adaptá `<skill-dir>/scripts/hitl-loop.template.sh`, corré esa sesión con la
persona, y pegá la corrida real en el `state.md` antes de este paso — el
validador no le va a pedir que repita los clicks 3 veces.

### 4. Capa semántica (todavía manual)

El validador mecánico **no puede saber** si el rojo que produce el comando
corresponde al síntoma exacto que describió la persona, o a un fallo
parecido pero distinto. Antes de dar la fase por cerrada, releé vos mismo
`SINTOMA_USUARIO` contra `## Corrida real` en el `state.md` y confirmá
explícitamente que coinciden. Si hay ambigüedad, no sigas — volvé al
usuario con la duda puntual en vez de asumir.

*(Esta capa todavía no tiene un script propio — es el siguiente paso a
diseñar del sistema completo. Por ahora, hacé esta comparación vos mismo,
de forma explícita, antes de acumular.)*

### 5. Acumular y cerrar la fase

Solo después de `READY` **y** de confirmar la capa semántica:

```bash
<skill-dir>/scripts/diagnostico_state.sh acumular <id> 1-construir-bucle "Fase 1: Construir bucle de feedback"
```

Esto agrega el contenido del `state.md` de esta fase a `DIAGNOSTICO.md`, el
acumulado persistido del diagnóstico completo. La Fase 2 (todavía no
mecanizada) parte de ese `DIAGNOSTICO.md`, no de esta conversación — así
sobrevive aunque el contexto se comprima o la sesión se reinicie.
