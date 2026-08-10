---
name: validar-requisitos
description: Audita la sección "Requisitos" de un PRD para que estén en formato Given/When/Then, orientados al resultado y sin prescribir implementación. Úsala dentro de crear-prd al auditar un borrador.
---

# Validar Requisitos

## Qué revisa

Que cada requisito sea un criterio de aceptación testeable, no una especificación de UI ni de implementación técnica.

## Checklist

- ¿Cada requisito tiene Given/When/Then (o un equivalente igual de verificable)?
- ¿El requisito describe un resultado observable, no una pantalla, componente o algoritmo específico?
- ¿Los requisitos no funcionales (performance, seguridad, accesibilidad) están separados de los funcionales y son reales para este producto, no agregados preventivamente?
- ¿Ningún requisito duplica información ya cubierta por otro?

## Si falla

Reescribí el requisito como resultado observable y dejá la decisión de implementación para diseño o desarrollo. Si un requisito no funcional no tiene una razón concreta, sacalo.
