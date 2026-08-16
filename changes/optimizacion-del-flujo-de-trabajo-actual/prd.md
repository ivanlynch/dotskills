# PRD: Optimización del flujo de trabajo actual

**Fecha:** 2026-08-15
**Estado:** Completo

---

## 1. Problema & Valor de Negocio

### Problema / Fricción
Hoy cada artefacto de la cadena (PRD, y a futuro spec, plan, etc.) se escribe en un formato pensado para lectura humana, sin una estructura predecible que la siguiente etapa pueda parsear directamente, por lo que la etapa siguiente tiene que reinterpretar el documento anterior en vez de consumirlo de forma directa.

### Objetivo & Resultado Esperado
Que cada artefacto de la cadena (empezando por el PRD) tenga una estructura predecible y con identificadores estables, para que la próxima etapa (spec técnica) pueda referenciar y consumir directamente cada requisito sin tener que reinterpretar prosa libre.

---

## 2. Alcance Funcional (Happy Path)

### Flujo Principal
1. Al ejecutar 'add --requerimiento', el script calcula automáticamente el próximo ID RF00N disponible contando los encabezados 'RF' ya presentes en el archivo, sin que el LLM tenga que llevar la cuenta.

### Requerimientos Funcionales
#### RF001: ID estable por requerimiento
Cada requerimiento funcional del PRD se registra con un ID RF00N asignado automáticamente por el script, no a mano por el LLM.

---

## 3. Zona de Exclusión (Out of Scope)

*Lo que explícitamente NO se construirá en esta primera versión:*
- Adoptar las secciones adicionales del ejemplo de test.md (Usuarios, Criterios de éxito, No funcional) queda fuera de esta entrega; solo se cambió el mecanismo de IDs en requerimientos.
