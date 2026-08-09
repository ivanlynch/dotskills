---
name: referencia
description: Crea documentación de referencia técnica basada en Diátaxis para consultar información mientras se trabaja. Úsala para APIs, comandos, opciones, parámetros, estados y errores.
---

# Referencia

## Fundamentos de Diátaxis

La referencia sirve al usuario que está trabajando y necesita aplicar conocimiento existente. Su obligación es describir la maquinaria con precisión, neutralidad y cobertura suficiente para una consulta rápida.

Su forma natural incluye listas, tablas, definiciones, firmas y descripciones. Puede contener ejemplos mínimos e ilustrativos, pero no debe transformarse en una explicación discursiva ni en una guía de pasos. Organiza el contenido de forma que refleje la arquitectura real y permita localizar la información.

## Procedimiento

1. Define la superficie que debe cubrirse: comandos, APIs, opciones, parámetros, clases, métodos, estados, errores o compatibilidades.
2. Inspecciona la implementación, configuración, pruebas y documentación local.
3. Construye una estructura navegable y coherente con la arquitectura documentada.
4. Describe cada elemento con nombres, tipos, valores permitidos, comportamiento, restricciones y errores verificables.
5. Usa tablas o listas cuando mejoren la consulta.
6. Añade ejemplos breves solo para ilustrar uso o sintaxis.
7. Enlaza a guías para tareas, tutoriales para aprendizaje y explicaciones para causas o decisiones.

## Fuentes y precisión

Cada dato debe poder rastrearse al código, configuración, pruebas, documentación oficial o fuente aprobada. No inventes una API, opción, salida, valor por defecto o compatibilidad. Señala elementos no verificables como pendientes.

## Validación específica

- ¿La información puede consultarse rápidamente?
- ¿La cobertura coincide con la superficie real?
- ¿Los nombres y firmas coinciden con la implementación?
- ¿Los valores, estados y errores están respaldados?
- ¿Los ejemplos son ilustrativos y no digresiones?
- ¿Se mantiene separada de explicación y procedimiento?
