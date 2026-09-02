---
name: diagnosticar-bugs
description: Bucle de diagnóstico para bugs difíciles y regresiones de rendimiento. Usar cuando el usuario pida diagnosticar o depurar algo, o informe que algo está roto, lanza errores, falla o funciona lentamente.
license: MIT (c) Matt Pocock — ver LICENSE en este directorio
metadata:
  source: https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs
  adaptation: traducción al español
---

# Diagnosticar bugs

Una disciplina para bugs difíciles. Omití fases únicamente cuando exista una justificación explícita.

Al explorar el código, leé `CONTEXT.md` (si existe) para construir un modelo mental claro de los módulos relevantes y revisá los ADR del área que estás modificando.

## Redactar secretos

Este skill requiere mostrar comandos, salidas y artefactos capturados. **Redactá primero todos los secretos**: reemplazalos por `<REDACTED>`. Construí los bucles usando variables de entorno, para que la credencial permanezca en el entorno y no aparezca en lo que mostrás. Los artefactos capturados pueden contener encabezados de autenticación: citá únicamente las líneas que contienen la señal relevante.

Si la salida redactada no alcanza para diagnosticar el bug, decilo y pedile información al usuario.

## Fase 1: construir un bucle de feedback

**Este es el skill.** Todo lo demás es mecánico. Si tenés una señal ajustada de pasa/falla para el bug —una que se ponga en rojo con _este_ bug—, vas a encontrar la causa; la bisección, la comprobación de hipótesis y la instrumentación solo consumen esa señal. Sin ella, mirar el código no alcanza.

Dedicá un esfuerzo desproporcionado a esta fase. **Sé agresivo, creativo y no te rindas.**

### Formas de construirlo, aproximadamente en este orden

1. **Test fallido** en cualquier frontera que alcance el bug: unitario, integración o e2e.
2. **Script curl / HTTP** contra un servidor de desarrollo en ejecución.
3. **Invocación de CLI** con una entrada fixture, comparando stdout con un snapshot conocido como correcto.
4. **Script de navegador headless** (Playwright / Puppeteer) que conduzca la UI y haga aserciones sobre DOM, consola o red.
5. **Reproducción de un trace capturado.** Guardá en disco una petición de red, payload o registro de eventos real; reproducilo a través del código de forma aislada.
6. **Arnés descartable.** Levantá el subconjunto mínimo del sistema —un servicio y dependencias simuladas— que ejercite el camino del bug con una sola llamada de función.
7. **Bucle de propiedades / fuzzing.** Si el bug produce una salida incorrecta solo a veces, ejecutá 1000 entradas aleatorias y buscá el modo de falla.
8. **Arnés de bisección.** Si el bug apareció entre dos estados conocidos —commit, dataset o versión—, automatizá «iniciar en el estado X y comprobar» para poder usar `git bisect run`.
9. **Bucle diferencial.** Ejecutá la misma entrada con la versión anterior y la nueva —o con dos configuraciones— y compará las salidas.
10. **Script bash HITL.** Como último recurso, si una persona debe hacer clic, guiala con `scripts/hitl-loop.template.sh` para que el bucle siga estructurado. La salida capturada vuelve al agente.

Construir el bucle de feedback correcto deja el bug resuelto en un 90%.

### Ajustar el bucle

Tratalo como un producto. Una vez que tengas un bucle, ajustalo:

- ¿Podés hacerlo más rápido? (Cacheá la preparación, omití inicialización no relacionada y acotá el alcance del test.)
- ¿Podés hacer más nítida la señal? (Afirmá el síntoma específico, no solo «no se cayó».)
- ¿Podés hacerlo más determinista? (Fijá el tiempo, usá una semilla para el RNG, aislá el filesystem y congelá la red.)

Un bucle flaky de 30 segundos apenas es mejor que no tener ninguno; uno determinista de 2 segundos es una superpotencia de debugging.

### Bugs no deterministas

El objetivo no es una reproducción perfecta, sino una **mayor tasa de reproducción**. Repetí el disparador 100 veces, paralelizá, agregá estrés, estrechá ventanas temporales e inyectá esperas. Un bug que falla el 50% de las veces se puede depurar; uno del 1% no, así que seguí aumentando la tasa hasta que sea abordable.

### Cuando realmente no podés construir un bucle

Detenete y decilo explícitamente. Enumerá lo que intentaste. Pedile al usuario: (a) acceso al entorno donde se reproduce, (b) un artefacto capturado y redactado (archivo HAR, volcado de logs, core dump o grabación de pantalla con timestamps), o (c) permiso para agregar instrumentación temporal en producción. **No avances a formular hipótesis sin un bucle.**

### Criterio de finalización: un bucle ajustado que se ponga en rojo

La Fase 1 termina cuando el bucle es ajustado y capaz de ponerse en rojo: podés nombrar **un comando** —ruta de script, invocación de test o curl— que ya ejecutaste al menos una vez, mostrando la invocación y su salida redactada, y que sea:

- [ ] **Capaz de ponerse en rojo:** recorre el camino real del bug y comprueba el **síntoma exacto del usuario**, de modo que pueda fallar con este bug y pasar una vez corregido. No alcanza con «se ejecuta sin errores».
- [ ] **Determinista:** produce el mismo veredicto en cada ejecución (para bugs flaky: una tasa de reproducción alta y fijada, según lo anterior).
- [ ] **Rápido:** segundos, no minutos.
- [ ] **Ejecutable por el agente:** corre sin supervisión; la intervención humana solo se permite mediante `scripts/hitl-loop.template.sh`.

Si te descubrís leyendo código para construir una teoría antes de que exista este comando, detenete: saltar directamente a una hipótesis es exactamente el fallo que este skill previene. Sin un comando capaz de ponerse en rojo, no hay Fase 2.

## Fase 2: reproducir y minimizar

Ejecutá el bucle. Observá cómo se pone en rojo cuando aparece el bug.

Confirmá:

- [ ] El bucle produce el modo de falla que describió el **usuario**, no otro fallo cercano. Bug equivocado = arreglo equivocado.
- [ ] El fallo se reproduce en varias ejecuciones (o, para bugs no deterministas, con una tasa suficientemente alta para depurarlo).
- [ ] Capturaste el síntoma exacto (mensaje de error, salida incorrecta o tiempo lento) para que las fases posteriores puedan verificar que el arreglo realmente lo resuelve.

### Minimizar

Una vez en rojo, reducí la reproducción al **escenario más pequeño que todavía se ponga en rojo**. Quitá entradas, callers, configuración, datos y pasos **de a uno**, ejecutando de nuevo el bucle después de cada recorte; conservá solo lo que sea estructural para la falla.

Esto importa porque una reproducción mínima reduce el espacio de hipótesis en la Fase 3 y se convierte en el test de regresión limpio de la Fase 5.

Terminaste cuando cada elemento restante sea estructural: quitar cualquiera hace que el bucle pase a verde. No avances hasta haber reproducido **y** minimizado.

## Fase 3: formular hipótesis

Generá **3 a 5 hipótesis ordenadas** antes de probar cualquiera. Generar una sola hace que te ancles en la primera idea plausible.

Cada hipótesis debe poder **refutarse**: expresá la predicción que hace.

> Formato: «Si <X> es la causa, entonces <cambiar Y> hará desaparecer el bug / <cambiar Z> lo empeorará».

Si no podés expresar la predicción, la hipótesis es una intuición sin fundamento: descartala o hacela más precisa.

**Mostrale la lista ordenada al usuario antes de probarla.** El usuario puede aportar conocimiento del dominio y reordenarla de inmediato («acabamos de desplegar un cambio relacionado con la #3») o saber qué hipótesis ya descartó. Es un punto de control barato y ahorra mucho tiempo. No te bloquees esperando: si el usuario no responde, avanzá con tu ordenamiento.

## Fase 4: instrumentar

Cada sondeo debe corresponder a una predicción específica de la Fase 3. **Cambiá una sola variable por vez.**

Preferencia de herramientas:

1. **Debugger / inspección en REPL**, si el entorno lo permite. Un breakpoint vale más que diez logs.
2. **Logs dirigidos** en los límites que distinguen las hipótesis.
3. Nunca «loguees todo y hacé grep».

**Etiquetá cada log de debug** con un prefijo único, por ejemplo `[DEBUG-a4f2]`. Limpiar al final se reduce a un solo grep. Los logs sin etiqueta sobreviven; los etiquetados se eliminan.

**Rama de rendimiento.** Para regresiones de rendimiento, los logs suelen ser incorrectos. Establecé primero una medición de referencia —arnés de tiempos, `performance.now()`, profiler o plan de consulta— y después hacé bisección. Medí primero, corregí después.

## Fase 5: corregir y agregar el test de regresión

Escribí el test de regresión **antes del arreglo**, pero solo si existe una **frontera correcta** para hacerlo.

Una frontera correcta es aquella donde el test ejercita el **patrón real del bug** tal como ocurre en el punto de llamada. Si la única frontera disponible es demasiado superficial —un test de un único caller cuando el bug necesita varios callers, o un test unitario que no puede reproducir la cadena que lo disparó—, el test da una falsa sensación de seguridad.

**Si no existe una frontera correcta, ese hecho es el hallazgo.** Documentalo. La arquitectura del código impide fijar el bug. Señalalo para la siguiente fase.

Si existe una frontera correcta:

1. Convertí la reproducción minimizada en un test fallido en esa frontera.
2. Observá cómo falla.
3. Aplicá el arreglo.
4. Observá cómo pasa.
5. Volvé a ejecutar el bucle de feedback de la Fase 1 contra el escenario original, sin minimizar.

## Fase 6: limpiar

Requisitos antes de declarar terminado el trabajo:

- [ ] La reproducción original ya no ocurre (volvé a ejecutar el bucle de la Fase 1).
- [ ] El test de regresión pasa (o está documentada la ausencia de una frontera adecuada).
- [ ] Se eliminó toda la instrumentación `[DEBUG-...]` (buscá el prefijo con `grep`).
- [ ] Se eliminaron los prototipos descartables (o se movieron a una ubicación de debug claramente marcada).
- [ ] La hipótesis que resultó correcta está expresada en el mensaje del commit o PR, para que el próximo debugger aprenda de ella.
