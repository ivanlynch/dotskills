<!--
Instrucciones internas de la fase "limpiar" de diagnosticar-bugs. No es
un SKILL.md a propósito: Codex descubre SKILL.md de forma recursiva en
todo el árbol symlinkeado, y esta fase no tiene sentido invocada por su
cuenta — solo como parte del flujo de diagnosticar-bugs.

Todavía no está mecanizada (a diferencia de fases/construir-bucle/):
es el mismo contenido que tenía como sección de SKILL.md, movido acá
sin cambios de fondo.
-->

# Fase 6: limpiar

Requisitos antes de declarar terminado el trabajo:

- [ ] La reproducción original ya no ocurre (volvé a ejecutar el bucle de la Fase 1).
- [ ] El test de regresión pasa (o está documentada la ausencia de una frontera adecuada).
- [ ] Se eliminó toda la instrumentación `[DEBUG-...]` (buscá el prefijo con `grep`).
- [ ] Se eliminaron los prototipos descartables (o se movieron a una ubicación de debug claramente marcada).
- [ ] La hipótesis que resultó correcta está expresada en el mensaje del commit o PR, para que el próximo debugger aprenda de ella.
