---
name: crear-prd
description: Guía la redacción de un PRD (documento de requisitos de producto) enfocado primero en el cliente, el problema y la métrica de éxito, separa evidencia real de supuestos sin validar mediante /entrevistar, y audita el resultado contra antipatrones conocidos (specs congeladas, sobre-especificación, falta de participación del equipo) antes de entregarlo. Úsala cuando el usuario quiera escribir, revisar o mejorar un PRD, un documento de requisitos de producto o una especificación de producto.
---

# Crear PRD

Guía la redacción de un documento de requisitos de producto (PRD) enfocado en el "por qué" antes que en el "qué", separa evidencia real de supuestos sin validar, y audita el resultado contra antipatrones conocidos antes de entregarlo.

## Principios

- El PRD es un documento vivo: se espera que cambie. Versionalo y dejá explícito cuándo y por qué se actualizó.
- No es una lista de features: primero cliente, problema y métrica de éxito; recién después, requisitos.
- Los requisitos son criterios de aceptación testeables (outcomes), no specs de UI ni de implementación.
- Toda afirmación es evidencia real (entrevistas, datos, tickets) o un supuesto explícito por validar — nunca una mezcla sin etiquetar.

Antes de redactar, leé `references/patrones.md` (dentro de esta misma skill) para los patrones concretos que sigue un buen PRD.

## Flujo

### 1. Gate del porqué

Antes de escribir cualquier requisito, cerrá:

- **Cliente:** a quién le resuelve esto, con la mayor especificidad posible (evitá "todos los usuarios").
- **Problema:** qué le pasa hoy a ese cliente sin esto.
- **Métrica de éxito:** cómo se sabrá que funcionó, en términos medibles (ej. "bajar el tiempo de onboarding de 5 a 3 minutos"), no vagos ("mejorar la experiencia").

Investigá primero si ya existe evidencia en el workspace: tickets, entrevistas de clientes, analíticas, investigación previa. Si la encontrás, usala y citá la fuente (archivo, ticket, fecha). Si no existe, aplicá `/entrevistar`: una pregunta por vez, con recomendación, y esperá la respuesta. Marcá la respuesta como **supuesto** (no como hecho) si no está respaldada por evidencia real.

No avances a la sección de requisitos sin cerrar esto.

### 2. Evidencia y supuestos

Mantené dos listas separadas y visibles en el documento:

- **Evidencia:** lo respaldado por una fuente verificable (entrevista, dato, ticket, commit). Citá la fuente.
- **Supuestos:** lo que se cree pero no se validó todavía. Cada supuesto necesita un plan para validarlo (quién, cómo, cuándo) o se marca como riesgo abierto.

Nunca presentes un supuesto como si fuera un hecho confirmado.

### 3. Alcance

Definí explícitamente qué queda dentro y qué queda fuera. Un alcance sin exclusiones explícitas es señal de sobre-especificación temprana (ver `references/antipatrones.md`).

### 4. Requisitos como criterios de aceptación

Redactá cada requisito en formato Given/When/Then (o equivalente), orientado al resultado observable, no a la solución técnica ni al diseño de UI. Si un requisito prescribe una pantalla o un flujo específico sin dejar margen a diseño o desarrollo, revisalo.

Sumá requisitos no funcionales (performance, seguridad, accesibilidad, compatibilidad) solo si son reales para este producto — no los agregues preventivamente.

### 5. Documento vivo

Incluí una sección de versión/changelog: fecha, qué cambió, quién lo actualizó. El PRD nunca se "cierra": se actualiza cuando cambia el entendimiento. Dejá explícito cómo se van a enterar diseño y desarrollo de una actualización; no asumas que lo van a revisar por su cuenta.

Usá `assets/plantilla-prd.md` como estructura base del documento. Escribí el archivo en `specs/<slug>/prd.md` dentro del repo del proyecto donde se está trabajando (no en este repo de skills), con `<slug>` en kebab-case derivado del nombre de la iniciativa — no del ticket, porque el PRD suele definirse antes de que exista un ticket. Si `specs/<slug>/` no existe, creala.

### 6. Auditoría

Antes de entregar:

1. Corré `<skill-dir>/scripts/validar_prd.sh <ruta-del-prd>` para confirmar que están las 8 secciones obligatorias. Si falta alguna, agregala antes de seguir.
2. Leé y aplicá, cada una dentro de esta misma skill:
   - `skills/validar-porque/SKILL.md` para auditar cliente, problema y métrica de éxito.
   - `skills/validar-evidencia/SKILL.md` para auditar la separación entre evidencia y supuestos.
   - `skills/validar-alcance/SKILL.md` para auditar que el alcance tenga exclusiones explícitas.
   - `skills/validar-requisitos/SKILL.md` para auditar que los requisitos sean Given/When/Then y no prescriban implementación.
3. Revisá el documento contra `references/antipatrones.md`. Si encontrás alguno, corregilo o dejalo señalado explícitamente como riesgo aceptado por el usuario — no lo ignores en silencio.

### 7. Entrega

Entregá la ruta del PRD (`specs/<slug>/prd.md`) junto con: la lista de supuestos pendientes de validar, las fuentes de evidencia usadas y el resultado de la auditoría (script + sub-skills + antipatrones).

## Skills relacionadas

- `/entrevistar`: resuelve cada decisión abierta (cliente, problema, métrica, alcance) una pregunta a la vez, con recomendación.
