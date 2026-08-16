# Spec: Optimización del flujo de trabajo actual

**Fecha:** 2026-08-15
**Estado:** Completo
**PRD:** changes/optimizacion-del-flujo-de-trabajo-actual/prd.md

---

## RF-001: ID estable por requerimiento

### RF001E001: Asignación automática del siguiente ID
Dado que el PRD ya tiene 2 requerimientos registrados (RF-001 y RF-002)
Cuando se agrega un tercer requerimiento con 'add --requerimiento'
Entonces el script le asigna automáticamente el ID RF-003, sin que el LLM tenga que llevar la cuenta

### RF001E002: Primer requerimiento de un PRD vacío
Dado que el PRD no tiene ningún requerimiento registrado todavía
Cuando se agrega el primer requerimiento con 'add --requerimiento'
Entonces el script le asigna el ID RF-001
