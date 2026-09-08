# Fase 6: limpiar

Requisitos antes de declarar terminado el trabajo:

- [ ] La reproducción original ya no ocurre (volvé a ejecutar el bucle de la Fase 1).
- [ ] El test de regresión pasa (o `HALLAZGO` en `DIAGNOSTICO.md` documenta que no había un lugar correcto para testear).
- [ ] Se eliminó toda la instrumentación `[DEBUG-...]` (buscá el prefijo con `grep`).
- [ ] Se eliminaron los prototipos descartables (o se movieron a una ubicación de debug claramente marcada).
- [ ] La hipótesis que resultó correcta está expresada en el mensaje del commit o PR, para que el próximo debugger aprenda de ella.
