# Patrones de un buen PRD

Checklist de qué hacer al redactar un PRD. Complementa `antipatrones.md` (qué evitar).

## Antes de escribir requisitos

- Cliente específico, no "todos los usuarios".
- Problema descrito en términos del cliente, no de la solución.
- Métrica de éxito medible, con un valor objetivo o umbral claro.

## Al documentar evidencia

- Cada afirmación de evidencia cita su fuente (entrevista, dato, ticket, commit).
- Cada supuesto tiene un plan de validación (quién, cómo, cuándo) o queda marcado como riesgo abierto.

## Al definir alcance

- El alcance lista exclusiones explícitas, no solo lo incluido.

## Al escribir requisitos

- Formato Given/When/Then, orientado al resultado observable.
- Sin prescribir pantallas, componentes ni decisiones de implementación.
- Requisitos no funcionales solo si son reales para este producto.

## Documento vivo

- Tiene changelog con fecha, cambio y autor.
- Define cómo se notifica una actualización a diseño y desarrollo.
