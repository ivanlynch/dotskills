<!--
Instrucciones internas de la fase "corregir y testear" de
diagnosticar-bugs. No es un SKILL.md a propósito: Codex descubre
SKILL.md de forma recursiva en todo el árbol symlinkeado, y esta fase
no tiene sentido invocada por su cuenta — solo como parte del flujo de
diagnosticar-bugs.

Todavía no está mecanizada (a diferencia de fases/construir-bucle/):
es el mismo contenido que tenía como sección de SKILL.md, movido acá
sin cambios de fondo.
-->

# Fase 5: corregir y agregar el test de regresión

Escribí el test de regresión **antes del arreglo**, pero solo si existe una **frontera correcta** para hacerlo.

Una frontera correcta es aquella donde el test ejercita el **patrón real del bug** tal como ocurre en el punto de llamada. Si la única frontera disponible es demasiado superficial —un test de un único caller cuando el bug necesita varios callers, o un test unitario que no puede reproducir la cadena que lo disparó—, el test da una falsa sensación de seguridad.

**Si no existe una frontera correcta, ese hecho es el hallazgo.** Documentalo. La arquitectura del código impide fijar el bug. Señalalo para la siguiente fase.

Si existe una frontera correcta:

1. Convertí la reproducción minimizada en un test fallido en esa frontera.
2. Observá cómo falla.
3. Aplicá el arreglo.
4. Observá cómo pasa.
5. Volvé a ejecutar el bucle de feedback de la Fase 1 contra el escenario original, sin minimizar.
