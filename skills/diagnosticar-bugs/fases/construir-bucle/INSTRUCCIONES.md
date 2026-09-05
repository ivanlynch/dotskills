# Fase: Construir bucle de feedback

## Flujo

### 1. Copiar la plantilla y completarla

```bash
cp <skill-dir>/fases/construir-bucle/TEMPLATE.md \
   "$(<skill-dir>/scripts/estado.sh ruta-fase <id> construir-bucle)"
```

Completá cada campo siguiendo la Fase 2 de `SKILL.md` (mismo criterio: probá
los métodos en el orden de esa lista, sé agresivo y creativo, no te rindas).
**No tildes las casillas de "condiciones de salida" vos mismo** — eso lo
hace el validador en el paso siguiente.

**Cómo decidís `TIPO_BUCLE`:** por defecto es `automatico`. Es `hitl`
únicamente cuando probaste los primeros 9 métodos de esa lista y ninguno
te sirvió — es el método #10, el último recurso, no una opción más entre
las otras. Si llegás ahí, copiá y adaptá
`<skill-dir>/scripts/hitl-loop.template.sh`, corré esa sesión con la
persona, y pegá la corrida real bajo `## Corrida real` en el `state.md`
**antes de pasar al paso 2** — el validador no le va a pedir que repita
los clicks 3 veces, así que necesita esa evidencia ya escrita.

### 2. Correr el validador

```bash
<skill-dir>/fases/construir-bucle/scripts/validar.sh "$(<skill-dir>/scripts/estado.sh ruta-fase <id> construir-bucle)"
```

Valida dos capas, en orden:

1. **Completitud estructural**: que `SINTOMA_USUARIO`, `METODO`, `COMANDO`,
   `TIPO_BUCLE` (con un valor válido: `automatico` o `hitl`) y `AJUSTES`
   estén completos. Si falta algo, corta acá — ni siquiera intenta correr
   el comando.
2. **Verificación mecánica**: re-corre el `COMANDO` declarado de verdad (3
   veces si es automático) y confirma las 4 condiciones de salida.

- Imprime `READY` (exit 0) si pasa las dos capas.
- Imprime `NOT_READY` (exit 1) con el motivo exacto por stderr si no. Volvé
  al paso 1, ajustá lo que falte según lo que diga el error, y volvé a
  correr el validador. No sigas a la fase siguiente sin `READY`.

### 3. Capa semántica (todavía manual)

El validador mecánico **no puede saber** si el rojo que produce el comando
corresponde al síntoma exacto que describió la persona, o a un fallo
parecido pero distinto. Antes de dar la fase por cerrada, releé vos mismo
`SINTOMA_USUARIO` contra `## Corrida real` en el `state.md` y confirmá
explícitamente que coinciden. Si hay ambigüedad, no sigas — volvé al
usuario con la duda puntual en vez de asumir.

*(Esta capa todavía no tiene un script propio — es el siguiente paso a
diseñar del sistema completo. Por ahora, hacé esta comparación vos mismo,
de forma explícita, antes de acumular.)*

### 4. Acumular y cerrar la fase

Solo después de `READY` **y** de confirmar la capa semántica:

```bash
<skill-dir>/scripts/estado.sh acumular <id> construir-bucle "Fase: Construir bucle de feedback"
```

Esto agrega el contenido del `state.md` de esta fase a `DIAGNOSTICO.md`, el
acumulado persistido del diagnóstico completo (bajo el proyecto actual). La
fase siguiente (todavía no mecanizada) parte de ese `DIAGNOSTICO.md`, no de
esta conversación — así sobrevive aunque el contexto se comprima o la
sesión se reinicie.
