---
name: analizar-alcance
description: Analiza el tamaño y alcance de un issue para determinar si puede completarse, entregarse e integrarse de forma independiente. Detecta riesgos, dependencias y señales de que debe dividirse en subtareas verticales y testeables. No depende de ningún tracker en particular: funciona con un ID de Jira, GitHub, Linear o sin ID.
---

# Analizar Alcance

Evalúa si un issue tiene un tamaño adecuado para ser completado e integrado de forma independiente. El análisis debe priorizar la capacidad de llegar a `Done` con evidencia clara, no una estimación basada únicamente en días de calendario.

## Flujo de análisis

El alcance se analiza como un árbol recursivo persistido en `scope_analysis` mediante `<skill-dir>/scripts/workflow_state.py`. Mantener la fase `analizar-alcance` en `IN_PROGRESS` hasta que todas las hojas del árbol estén en `DONE`.

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

### 2. Registrar el issue y resolver su identificador

- Si el issue ya tiene un ID de algún tracker (Jira, GitHub, Linear u otro), úsalo tal cual: no le exijas ni le fuerces ningún formato particular.
- Si no existe ningún ID (una idea sin trackear), obtén uno interno con `workflow_state.py next-id` y úsalo como identificador en todos los pasos siguientes.
- Si `/cocinar` ya inicializó el registro para este ID (fase `ticket` en `DONE`), continúa directamente en el paso 3.
- Si corrés este análisis de forma independiente (sin `/cocinar`), inicializa el registro vos mismo antes de tocar `scope_analysis`:

  ```bash
  python3 <skill-dir>/scripts/workflow_state.py init <ID>
  python3 <skill-dir>/scripts/workflow_state.py start <ID> ticket
  python3 <skill-dir>/scripts/workflow_state.py context <ID> --id "<ID>" --title "<título breve>" --description "<resumen del objetivo>" --source user
  python3 <skill-dir>/scripts/workflow_state.py done <ID> ticket --evidence "<origen del contexto>"
  python3 <skill-dir>/scripts/workflow_state.py start <ID> analizar-alcance
  ```

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
- criterios de aceptación verificables (necesarios para el paso 7 y para el handoff a `/plan`);
- forma de probarla e integrarla de manera independiente.

### 7. Cerrar el análisis en el árbol

Registra cada nodo y sus relaciones padre/hijo con `workflow_state.py scope`. El documento debe incluir, además de `status`/`root`/`items`, el campo `objective` (el objetivo general del issue, del paso 1) y, en cada nodo hoja con `verdict: APTO_PARA_IMPLEMENTAR`, un campo `acceptance_criteria` con la lista de criterios verificables de esa hoja — son los mismos datos del paso 6, no los redactes dos veces.

Ejecuta `workflow_state.py validate` después de cada actualización. Si algún nodo queda `BLOCKED`, invoca `/entrevistar`, resuelve una decisión por turno y volvé a analizar el mismo nodo. Si un nodo requiere división, agregá sus hijos y analizá cada uno de forma recursiva. No concluyas hasta que todos los nodos sean hojas `DONE` o exista un bloqueo explícito que requiera intervención del usuario.

El análisis completo solo puede marcarse como `CONFIRMED` cuando:

- el árbol tiene un nodo raíz válido y un `objective` no vacío;
- cada hijo referencia a su padre y cada padre referencia a sus hijos;
- cada nodo tiene título, estado y veredicto válidos;
- cada hoja `APTO_PARA_IMPLEMENTAR` tiene `acceptance_criteria` no vacío;
- cada hoja está en `DONE` con veredicto `APTO_PARA_IMPLEMENTAR` y cada padre dividido está en `DONE` con veredicto `REQUIERE_DIVISION`;
- no existe ningún nodo `BLOCKED`, `PENDING` o `IN_PROGRESS`.

Marca la fase `analizar-alcance` como `DONE` recién en este punto.

### 8. Escribir y validar el veredicto

El único entregable narrativo es este veredicto final — no generes ningún resumen intermedio antes de llegar acá.

1. Obtené el path del archivo: `workflow_state.py verdict-path <ID>`.
2. Copiá `<skill-dir>/veredicto-template.md` a ese path.
3. Completá cada `{{TOKEN}}` con contenido real. El bloque "Subtareas propuestas" es repetible: duplicalo una vez por cada work item si el veredicto raíz es `REQUIERE DIVISIÓN`; si es `APTO PARA IMPLEMENTAR`, dejá únicamente "Ninguna" en esa sección.
4. Validá con `workflow_state.py check-verdict <ID>`. Si falla porque quedaron placeholders, completalos y volvé a validar.
5. Mostrá el contenido final del archivo como tu respuesta.

### 9. Entregar el handoff a `/plan`

Cuando `scope_analysis` esté `CONFIRMED`, ejecutá `workflow_state.py handoff <ID>` y entregá esa salida (`action=ANALYSIS_COMPLETE`, `next_phase=plan`, `scope_handoff`) tal cual como contrato de entrada de `/plan`. No reconstruyas ni redactes ese JSON a mano.

## Reglas de calidad

- No uses solo una estimación temporal para aprobar o dividir un issue.
- No dividas horizontalmente en tareas que no puedan probarse o entregar valor.
- Prefiere pocas subtareas verticales, independientes y testeables.
- Mantén las recomendaciones breves y accionables.
- Distingue hechos observados, inferencias y decisiones pendientes.
- No dejes ningún `{{TOKEN}}` sin completar en el veredicto final.
- No implementes cambios ni abras una PR.
