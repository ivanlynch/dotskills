---
name: investigar
description: Investiga bugs, regresiones, fallos de rendimiento, configuración e integraciones mediante entrevista, reproducción controlada, hipótesis verificables, criterios de falsación, evidencia dinámica y análisis de impacto. Usar cuando haya que determinar una causa raíz o documentar una investigación técnica reproducible antes de proponer una solución.
---

# Investigar

Investiga problemas técnicos sin modificar el proyecto. El resultado es un informe local, reproducible y auditable; no implementes la solución.

## Reglas obligatorias

- Usa Bash para toda automatización. No escribas scripts Python, Node ni otros runtimes.
- Mantén todos los archivos de una investigación dentro de una única carpeta local externa al proyecto.
- No crees artefactos temporales fuera de esa carpeta.
- No modifiques archivos del proyecto.
- No instales dependencias ni cambies configuración sin confirmación explícita.
- Redacta secretos, tokens, credenciales, cookies y datos personales antes de persistir evidencia.
- Usa rutas relativas al referenciar artefactos en `investigacion.md`.
- No inventes resultados. Separa hechos observados, inferencias y supuestos.

## Inicio y persistencia

Pregunta de una en una y ofrece una recomendación breve. Reúne estas cinco respuestas antes de formular hipótesis:

1. **Síntoma frente a comportamiento esperado:** «¿Qué está ocurriendo exactamente —logs, errores, métricas o comportamientos inesperados— y qué debería ocurrir en su lugar?»
2. **Contexto y fronteras:** «¿En qué archivos, módulos, endpoints o flujos sospechas o confirmas que se origina el problema?»
3. **Condiciones de reproducción:** «¿Bajo qué condiciones específicas ocurre —dispositivo/OS, versiones, payload, concurrencia o estado previo—?»
4. **Cambios recientes:** «¿Esto funcionaba antes? Si es así, ¿qué cambió recientemente —PRs, dependencias o feature flags—?»
5. **Fuentes de evidencia:** «¿Contamos con logs, traces, capturas, métricas o un stack trace completo?»

Cuando el usuario confirme el identificador, crea la carpeta con:

```bash
<skill-dir>/scripts/crear-estructura-investigacion.sh <identificador>
```

El script usa `INVESTIGACIONES_ROOT` o `~/Documents/research`, rechaza identificadores inválidos y no sobrescribe una carpeta existente. El template está en `assets/templates/investigacion.md`; no lo copies manualmente.

La estructura generada es fija:

```text
<id>/
├── investigacion.md
├── metadata/{manifest.tsv,respuestas.log,comandos.ndjson,entorno.txt}
├── evidencia/
├── reproduccion/
├── experimentos/
└── resultados/
```

Usa `metadata/manifest.tsv` como inventario determinista. Los IDs son `E-###` para evidencia, `R-###` para reproducciones, `H-###` para hipótesis, `X-###` para experimentos y `S-###` para fuentes externas. No renombres artefactos ya registrados: crea una nueva versión.

Para incorporar un archivo, usa el script y no copies archivos a mano:

```bash
<skill-dir>/scripts/registrar-artefacto.sh \
  --investigacion <id> \
  --tipo evidencia \
  --descripcion "Stack trace redactado" \
  --archivo /ruta/al/archivo-redactado.txt \
  --redactado
```

El script genera el ID, copia a la carpeta correcta, calcula SHA-256 y actualiza el manifiesto. Para fuentes externas registra URL, fecha, versión de contexto y afirmación respaldada en `investigacion.md` y `manifest.tsv`.

Para completar una sección del template, usa Bash y stdin:

```bash
printf '%s\n' "$RESPUESTA" | <skill-dir>/scripts/registrar-respuesta.sh \
  --investigacion <id> --seccion sintoma --texto-stdin
```

Las secciones permitidas son `sintoma`, `contexto`, `reproduccion`, `deltas`, `fuentes_evidencia`, `diagnostico_inicial`, `hipotesis`, `experimentos`, `analisis_impacto`, `conclusion_final` y `registro_decisiones`. El script sustituye únicamente el placeholder correspondiente, registra la operación en `metadata/respuestas.log` y rechaza secciones desconocidas.

Los scripts solo requieren Bash, utilidades POSIX, `awk`, `sed`, `grep`, `find`, `mktemp` y una herramienta de SHA-256 (`shasum` o `sha256sum`). No instalan dependencias. Si falta una herramienta necesaria, deben detenerse con un error claro. Cada script tiene su prueba Bash equivalente en `scripts/tests/`.

## Método de investigación

Después de las cinco respuestas, registra el diagnóstico inicial y confirma el alcance. Formula una hipótesis principal y alternativas. Cada hipótesis debe tener causa propuesta, predicción observable y criterio de falsación. Si no puede falsarse, detén la investigación con estado `HIPOTESIS_INCOMPLETA`.

Prioriza este orden:

1. Reproducción controlada.
2. Pruebas y experimentos repetibles.
3. Código y configuración ejecutados.
4. Logs, métricas y trazas.
5. Documentación oficial versionada.
6. Historial de cambios y reportes del equipo.

Puedes consultar fuentes externas en cualquier fase. Valida siempre su compatibilidad con las versiones y el contexto actuales, y registra URL y fecha.

Ejecuta comandos de diagnóstico de forma controlada. Registra comando, directorio de trabajo, entorno, timestamp, código de salida y rutas de stdout/stderr dentro de la investigación. No envíes outputs extensos al contexto si basta con guardar el archivo y resumirlo.

## Cuándo concluir

Hay cuatro niveles de conclusión:

- **Diagnóstico inicial:** después de la entrevista. Solo declara qué está delimitado y qué falta.
- **Reproducibilidad:** después del repro. Usa `REPRODUCIDO`, `NO_REPRODUCIDO`, `PARCIAL` o `NO_DETERMINABLE`; no afirma causa raíz.
- **Conclusión experimental:** después de cada experimento. Marca una hipótesis como `APOYADA`, `DEBILITADA`, `FALSADA` o `INCONCLUSA` y enlaza la evidencia.
- **Conclusión final:** solo cuando las cinco respuestas están completas, el repro y experimentos necesarios terminaron, se evaluaron alternativas, se hizo análisis de impacto y no quedan contradicciones relevantes.

La conclusión final debe ser `CONFIRMADA`, `FALSADA`, `INCONCLUSA` o `BLOQUEADA`. Incluye causa más probable, confianza, evidencia determinante, hipótesis descartadas, limitaciones, propuesta sin implementar y blast radius. Muéstrala al usuario y persístela como cierre solo después de su confirmación.

## Cierre

Actualiza `investigacion.md` incrementalmente. Antes de cerrar, revisa que cada afirmación importante tenga referencia a un ID o esté marcada como inferencia/supuesto. Conserva la carpeta completa; nunca borres archivos automáticamente. Si el usuario pide limpieza, solicita confirmación y actúa únicamente sobre la carpeta de esa investigación.
