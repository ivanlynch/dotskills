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
