# 0009. REPORT.md en la carpeta de la investigación, generado al cerrar Fase 6

## Estado

Aceptada

## Contexto

`DIAGNOSTICO.md` acumula, en orden, el contenido crudo de cada fase
cerrada — comentarios de plantilla incluidos. Sirve como estado
persistido para que el propio skill retome una investigación, pero no
como algo para leer de punta a punta: mezcla instrucciones para el
agente, campos vacíos de registros que no se usaron, y el historial
completo de hipótesis descartadas sin destacar cuál fue la que
importó.

No había ninguna salida legible, de una sola pasada, que respondiera
"¿qué encontramos, cómo lo encontramos, y qué se hizo al respecto?" —
útil para compartir en una PR, para el próximo debugger que toque este
código, o simplemente para no tener que releer `DIAGNOSTICO.md`
completo.

## Decisión

Al cerrar la Fase 6 (Limpiar), un paso nuevo genera `REPORT.md` junto
a `DIAGNOSTICO.md` — misma carpeta, `$DIAGNOSTICOS_ROOT/<slug-proyecto>/<id>/`.

- **Fuera del repo del proyecto, no versionado.** Mismo criterio que
  ya usa toda la skill: nada de `diagnosticar-bugs` toca el repo del
  usuario salvo el código del fix en sí. Compartirlo (PR, Slack, etc.)
  es una acción explícita de quien lo necesite, copiando el contenido
  — no un commit automático.
- **`scripts/generar-reporte.sh <id>`** arma las secciones mecánicas
  (problema, diagnóstico confirmado con su evidencia, tabla de
  hipótesis evaluadas, corrección aplicada) extrayendo campos que las
  Fases 0, 3, 4 y 5 ya escribieron — no inventa contenido, solo
  reordena y filtra lo que ya está.
- **`## Análisis final` queda en blanco**, con un comentario guía. Es
  la única sección que el agente redacta de cero: una síntesis de qué
  pasó, por qué, y qué se aprendió no es algo que se pueda extraer
  mecánicamente de campos sueltos — mismo criterio que ya separa, en
  el resto de la skill, lo mecanizable de lo que es criterio del
  agente (ej. `ES_MINIMO` en Fase 2, `JUSTIFICACION_MENOS_DE_3` en
  Fase 3).
- Se genera como último paso de Fase 6, después del validador
  mecánico y del checklist manual — el criterio de cierre de la fase
  ahora incluye que `REPORT.md` exista con `## Análisis final`
  completo.

## Consecuencias

- Cada investigación que llega a cerrar Fase 6 deja dos archivos en su
  carpeta: `DIAGNOSTICO.md` (estado crudo, para la skill) y
  `REPORT.md` (resumen legible, para personas).
- `generar-reporte.sh` no exige que las Fases 5/6 hayan cerrado —
  solo que la Fase 4 esté acumulada. Sirve también como snapshot de
  una investigación a medio terminar, aunque su uso previsto es al
  cerrar Fase 6.
- Si más adelante se necesita compartir el reporte automáticamente
  (ej. pegarlo en la descripción de la PR), es una decisión aparte:
  esta ADR no la resuelve, solo deja el contenido ya armado y listo
  para copiar.
