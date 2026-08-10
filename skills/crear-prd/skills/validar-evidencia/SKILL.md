---
name: validar-evidencia
description: Audita las secciones "Evidencia" y "Supuestos" de un PRD para que estén correctamente separadas, con fuente o plan de validación. Úsala dentro de crear-prd al auditar un borrador.
---

# Validar Evidencia

## Qué revisa

Que ninguna afirmación del PRD se presente como hecho sin serlo.

## Checklist

- ¿Cada ítem de "Evidencia" cita una fuente verificable (entrevista, dato, ticket, commit, fecha)?
- ¿Cada ítem de "Supuestos" tiene un plan de validación (quién, cómo, cuándo) o está reflejado como riesgo abierto?
- ¿Hay alguna afirmación en el cuerpo del documento (fuera de estas dos secciones) que suene a hecho pero en realidad sea un supuesto no listado?
- ¿Ningún supuesto aparece redactado como si ya estuviera confirmado?

## Si falla

Mové la afirmación a la sección correcta (Evidencia o Supuestos) y pedile al usuario la fuente o el plan de validación que falta.
