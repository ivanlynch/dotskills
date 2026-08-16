# Plan: Optimización del flujo de trabajo actual

**Fecha:** 2026-08-15
**Estado:** Completo
**Spec:** changes/optimizacion-del-flujo-de-trabajo-actual/spec.md

---

## Tareas
### T001: Asignar RF00N automáticamente al agregar un requerimiento
En agregar_requerimiento() de crear_prd.sh, contar los encabezados RF[0-9]+ existentes y asignar RF(N+1) al nuevo requerimiento, funcione con el PRD vacío o con requerimientos previos.
**Verificación:** Los tests scripts/tests/crear_prd.sh para RF001E001 y RF001E002 pasan en verde.
**Depende de:** Ninguna
**Cubre:** RF001E001 RF001E002

