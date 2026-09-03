<!--
Instrucciones internas de la fase "reproducir y minimizar" de
diagnosticar-bugs. No es un SKILL.md a propósito: Codex descubre
SKILL.md de forma recursiva en todo el árbol symlinkeado, y esta fase
no tiene sentido invocada por su cuenta — solo como parte del flujo de
diagnosticar-bugs.

Todavía no está mecanizada (a diferencia de fases/construir-bucle/):
es el mismo contenido que tenía como sección de SKILL.md, movido acá
sin cambios de fondo.
-->

# Fase 2: reproducir y minimizar

Ejecutá el bucle. Observá cómo se pone en rojo cuando aparece el bug.

Confirmá:

- [ ] El bucle produce el modo de falla que describió el **usuario**, no otro fallo cercano. Bug equivocado = arreglo equivocado.
- [ ] El fallo se reproduce en varias ejecuciones (o, para bugs no deterministas, con una tasa suficientemente alta para depurarlo).
- [ ] Capturaste el síntoma exacto (mensaje de error, salida incorrecta o tiempo lento) para que las fases posteriores puedan verificar que el arreglo realmente lo resuelve.

## Minimizar

Una vez en rojo, reducí la reproducción al **escenario más pequeño que todavía se ponga en rojo**. Quitá entradas, callers, configuración, datos y pasos **de a uno**, ejecutando de nuevo el bucle después de cada recorte; conservá solo lo que sea estructural para la falla.

Esto importa porque una reproducción mínima reduce el espacio de hipótesis en la Fase 3 y se convierte en el test de regresión limpio de la Fase 5.

Terminaste cuando cada elemento restante sea estructural: quitar cualquiera hace que el bucle pase a verde. No avances hasta haber reproducido **y** minimizado.
