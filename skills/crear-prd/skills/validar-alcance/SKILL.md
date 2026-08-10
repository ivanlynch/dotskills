---
name: validar-alcance
description: Audita la sección "Alcance" de un PRD para que tenga exclusiones explícitas, no solo lo incluido. Úsala dentro de crear-prd al auditar un borrador.
---

# Validar Alcance

## Qué revisa

Un alcance sin exclusiones explícitas es señal de sobre-especificación temprana o de límites no pensados.

## Checklist

- ¿La lista "Fuera" tiene al menos un ítem concreto (no está vacía ni dice "nada por ahora" sin justificación)?
- ¿Los ítems de "Dentro" y "Fuera" no se contradicen ni se superponen?
- ¿Alguna funcionalidad mencionada en otra sección del documento (evidencia, requisitos) queda fuera del alcance declarado sin que se note?

## Si falla

Pedile al usuario que decida explícitamente qué queda fuera antes de aprobar el alcance; no lo completes vos mismo con una suposición.
