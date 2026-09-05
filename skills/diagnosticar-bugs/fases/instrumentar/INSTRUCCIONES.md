# Fase 4: instrumentar

Cada sondeo debe corresponder a una predicción específica de la Fase 3. **Cambiá una sola variable por vez.**

Preferencia de herramientas:

1. **Debugger / inspección en REPL**, si el entorno lo permite. Un breakpoint vale más que diez logs.
2. **Logs dirigidos** en los límites que distinguen las hipótesis.
3. Nunca «loguees todo y hacé grep».

**Etiquetá cada log de debug** con un prefijo único, por ejemplo `[DEBUG-a4f2]`. Limpiar al final se reduce a un solo grep. Los logs sin etiqueta sobreviven; los etiquetados se eliminan.

**Rama de rendimiento.** Para regresiones de rendimiento, los logs suelen ser incorrectos. Establecé primero una medición de referencia —arnés de tiempos, `performance.now()`, profiler o plan de consulta— y después hacé bisección. Medí primero, corregí después.
