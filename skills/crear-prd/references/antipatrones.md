# Antipatrones de PRD

Checklist para auditar un PRD antes de entregarlo. Si encontrás alguno, corregilo
o dejalo señalado explícitamente como riesgo aceptado por el usuario.

## Antipatrones de proceso

- Existen especificaciones detalladas de todo el proyecto antes de que empiece el trabajo de ingeniería.
- Se exigen revisiones exhaustivas y aprobaciones rigurosas de todos los equipos antes de empezar.
- Diseño y desarrollo no se enteran cuándo se actualizaron los requisitos.
- Los requisitos nunca se actualizan, porque "ya los aprobaron todos".
- El documento se escribe sin la participación real del equipo (solo notas de quien lo redacta).

## Antipatrones de contenido

- Sobre-especificación: el documento dicta detalles de implementación o decisiones de UI que deberían quedar en manos de diseño o desarrollo.
- Sub-especificación: usa lenguaje vago ("fácil de usar", "rápido") en vez de criterios testeables.
- Objetivos no medibles: no se puede verificar si el resultado se cumplió o no.
- Evidencia y supuestos mezclados sin distinguirlos.
