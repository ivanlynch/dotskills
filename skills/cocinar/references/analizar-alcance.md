# Referencia: analizar alcance

Evalúa si el issue tiene un tamaño adecuado para ser completado e integrado de forma independiente. El análisis debe priorizar la capacidad de llegar a `Done` con evidencia clara, no una estimación basada únicamente en días de calendario.

## Flujo de análisis

El alcance se analiza como un árbol recursivo persistido en texto plano (sin JSON, sin Python) mediante `<skill-dir>/scripts/workflow_state.sh`. Mantener la fase `analizar-alcance` en `IN_PROGRESS` hasta que todas las hojas del árbol estén en `DONE`.

### 1. Reunir contexto

Usa la información disponible del issue, del repositorio y del workspace. Identifica:

- objetivo y resultado esperado;
- módulo, dominio o componente afectado;
- criterios de aceptación;
- dependencias técnicas o de negocio;
- capas y equipos involucrados;
- flujos, estados y roles que deben validarse;
- restricciones, riesgos y recursos pendientes.

Si un dato no figura de forma explícita en el issue o el código, márcalo como `[Requiere confirmación]`. No inventes estimaciones, dependencias ni criterios que no estén respaldados por el contexto. Si una decisión no puede resolverse investigando el entorno, invoca `/entrevistar` por cada punto ambiguo y espera su respuesta antes de continuar.

### 2. El registro ya está inicializado

`/cocinar` ya inicializó el registro para este ID (fase `ticket` en `DONE`) antes de llegar acá — continuar directamente en el paso 3, sin reinicializar nada.

### 3. Evaluar el tamaño ideal

Usa estas referencias como guía:

- **Ideal:** entre 0.5 y 2 días de trabajo efectivo por persona.
- **Límite máximo recomendado:** 3 días de trabajo efectivo.
- Si supera el límite o la incertidumbre es alta, recomienda dividirlo o reducir el alcance.

La duración es una señal, no el único criterio. Evalúa también si el issue puede desarrollarse, probarse, entregarse e integrarse sin depender de que varias tareas independientes terminen al mismo tiempo.

### 4. Aplicar criterios de independencia, tamaño y testabilidad

El issue debe ser:

- **Independiente:** puede desarrollarse, desplegarse e integrarse sin depender de otra tarea del mismo ciclo.
- **Pequeño:** cabe holgadamente en el ciclo de trabajo sin poner en riesgo el objetivo del Sprint.
- **Testeable:** tiene criterios de aceptación claros que permiten determinar si está terminado.

Registra cada criterio como `PASS`, `FAIL` o `UNKNOWN`, con una justificación breve.

### 5. Detectar señales para dividir

Recomienda dividir el issue si identificas una o más de estas señales:

1. Tiene más de 3 a 5 criterios de aceptación independientes.
2. Involucra múltiples capas técnicas, como backend, contrato de API, UI, persistencia local y telemetría en el mismo issue.
3. Incluye varios flujos o estados de negocio, como camino feliz, errores de red, estados vacíos y distintos roles de usuario.
4. La preparación de datos, las pruebas automatizadas o la validación de QA probablemente requieren más esfuerzo que el desarrollo.
5. Tiene dependencias que impiden entregar una parte funcional sin esperar a todas las demás.
6. Combina objetivos que podrían validarse y desplegarse por separado.

No dividas solo por capas técnicas. Prioriza incrementos verticales de valor que puedan probarse de extremo a extremo o aislarse mediante mocks, stubs o feature flags.

### 6. Proponer la división

Cuando el issue sea demasiado grande, propón subtareas que mantengan un resultado observable y criterios de aceptación propios. Usa, cuando corresponda, estas estrategias:

| Estrategia | Ejemplo de issue grande | División recomendada |
| --- | --- | --- |
| Por flujo | Implementar checkout completo | Checkout básico / camino feliz; después errores y validaciones |
| Por regla o modo de negocio | Soportar varios medios de pago | Tarjeta; Pix o transferencia; otros modos |
| Por capacidad de configuración o UI | Crear pantalla de perfil completa | Visualización; edición y persistencia |
| Por feature flag o stub | Pantalla dependiente de backend no disponible | UI con mocks o stubs; integración con API real |

Cada subtarea propuesta debe indicar:

- objetivo único;
- alcance y fuera de alcance;
- dependencia explícita, si existe;
- criterios de aceptación verificables (necesarios para el paso 7 y para la fase `plan`);
- forma de probarla e integrarla de manera independiente.

### 7. Cerrar el análisis en el árbol

Registra el objetivo general (del paso 1) una sola vez:

```bash
<skill-dir>/scripts/workflow_state.sh scope-set-objective <TICKET_ID> "<objetivo general del issue>"
```

Por cada nodo del árbol (raíz y cada subtarea), agregalo con su padre (`-` si es la raíz), status y verdict ya decididos:

```bash
<skill-dir>/scripts/workflow_state.sh scope-add-item <TICKET_ID> <item-id> <parent-id|-> <status> <verdict> "<título del nodo>"
```

Si el nodo es una hoja con `verdict=APTO_PARA_IMPLEMENTAR`, cargale los criterios de aceptación del paso 6 (son los mismos datos, no los redactes dos veces):

```bash
<skill-dir>/scripts/workflow_state.sh scope-set-criteria <TICKET_ID> <item-id> "<criterio 1>" "<criterio 2>" ...
```

Si más adelante cambia el status o el verdict de un nodo ya creado (por ejemplo, tras resolver un bloqueo), actualizalo sin recrearlo:

```bash
<skill-dir>/scripts/workflow_state.sh scope-set-item <TICKET_ID> <item-id> --status <S> --verdict <V>
```

Ejecuta `<skill-dir>/scripts/workflow_state.sh validate <TICKET_ID>` después de cada actualización. Si algún nodo queda `BLOCKED`, invoca `/entrevistar`, resuelve una decisión por turno y volvé a analizar el mismo nodo con `scope-set-item`. Si un nodo requiere división, agregá sus hijos con `scope-add-item` y analizá cada uno de forma recursiva. No concluyas hasta que todos los nodos sean hojas `DONE` o exista un bloqueo explícito que requiera intervención del usuario.

Cuando todos los nodos estén `DONE` y el objetivo esté cargado, confirmá el árbol completo:

```bash
<skill-dir>/scripts/workflow_state.sh scope-confirm <TICKET_ID>
```

Esto falla si algún nodo no cumple sus reglas (padre/hijo consistentes, hojas `APTO_PARA_IMPLEMENTAR` con criterios no vacíos, `REQUIERE_DIVISION` con hijos, etc.) — resolvé lo que indique el error y reintentá. Marca la fase `analizar-alcance` como `DONE` recién después de que `scope-confirm` funcione.

### 8. Escribir y validar el veredicto

El único entregable narrativo es este veredicto final — no generes ningún resumen intermedio antes de llegar acá.

1. Obtené el path del archivo: `<skill-dir>/scripts/workflow_state.sh verdict-path <TICKET_ID>`.
2. Copiá `<skill-dir>/assets/veredicto-template.md` a ese path.
3. Completá cada `{{TOKEN}}` con contenido real. El bloque "Subtareas propuestas" es repetible: duplicalo una vez por cada work item si el veredicto raíz es `REQUIERE DIVISIÓN`; si es `APTO PARA IMPLEMENTAR`, dejá únicamente "Ninguna" en esa sección.
4. Validá con `<skill-dir>/scripts/workflow_state.sh check-verdict <TICKET_ID>`. Si falla porque quedaron placeholders, completalos y volvé a validar.
5. Mostrá el contenido final del archivo como tu respuesta.

### 9. Entrega a la fase `plan`

No hay ningún paso manual de handoff: una vez que `scope-confirm` corrió con éxito (paso 7), la fase `plan` lee el árbol confirmado directamente desde el mismo registro con `plan_state.sh init <TICKET_ID>` — no le entregues ni redactes ningún documento a mano.

## Reglas de calidad

- No uses solo una estimación temporal para aprobar o dividir un issue.
- No dividas horizontalmente en tareas que no puedan probarse o entregar valor.
- Prefiere pocas subtareas verticales, independientes y testeables.
- Mantén las recomendaciones breves y accionables.
- Distingue hechos observados, inferencias y decisiones pendientes.
- No dejes ningún `{{TOKEN}}` sin completar en el veredicto final.
- No implementes cambios ni abras una PR.
