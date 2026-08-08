---
name: analizar-alcance
description: Analiza el tamaño y alcance de un ticket de Jira para determinar si puede completarse, entregarse e integrarse de forma independiente. Detecta riesgos, dependencias y señales de que debe dividirse en subtareas verticales y testeables.
---

# Analizar Alcance

Evalúa si un ticket de Jira tiene un tamaño adecuado para ser completado e integrado de forma independiente. El análisis debe priorizar la capacidad de llegar a `Done` con evidencia clara, no una estimación basada únicamente en días de calendario.

## Flujo de análisis

El alcance se analiza como un árbol recursivo persistido en `scope_analysis`. Mantener la fase `analizar-alcance` en `IN_PROGRESS` hasta que todas las hojas del árbol estén en `DONE`.

### 1. Reunir contexto

Usa la información disponible del ticket, del repositorio y del workspace. Identifica:

- objetivo y resultado esperado;
- módulo, dominio o componente afectado;
- criterios de aceptación;
- dependencias técnicas o de negocio;
- capas y equipos involucrados;
- flujos, estados y roles que deben validarse;
- restricciones, riesgos y recursos pendientes.

Si una decisión no puede resolverse investigando el entorno, invoca `$entrevistar`:

1. Haz una sola pregunta por turno.
2. Incluye una recomendación breve.
3. Espera la respuesta antes de continuar.

No inventes estimaciones, dependencias ni criterios que no estén respaldados por el contexto.

### 2. Evaluar el tamaño ideal

Usa estas referencias como guía:

- **Ideal:** entre 0.5 y 2 días de trabajo efectivo por persona.
- **Límite máximo recomendado:** 3 días de trabajo efectivo.
- Si supera el límite o la incertidumbre es alta, recomienda dividirlo o reducir el alcance.

La duración es una señal, no el único criterio. Evalúa también si el ticket puede desarrollarse, probarse, entregarse e integrarse sin depender de que varias tareas independientes terminen al mismo tiempo.

### 3. Aplicar criterios de independencia, tamaño y testabilidad

El ticket debe ser:

- **Independiente:** puede desarrollarse, desplegarse e integrarse sin depender de otra tarea del mismo ciclo.
- **Pequeño:** cabe holgadamente en el ciclo de trabajo sin poner en riesgo el objetivo del Sprint.
- **Testeable:** tiene criterios de aceptación claros que permiten determinar si está terminado.

Registra cada criterio como `PASS`, `FAIL` o `UNKNOWN`, con una justificación breve.

### 4. Detectar señales para dividir

Recomienda dividir el ticket si identificas una o más de estas señales:

1. Tiene más de 3 a 5 criterios de aceptación independientes.
2. Involucra múltiples capas técnicas, como backend, contrato de API, UI, persistencia local y telemetría en el mismo ticket.
3. Incluye varios flujos o estados de negocio, como camino feliz, errores de red, estados vacíos y distintos roles de usuario.
4. La preparación de datos, las pruebas automatizadas o la validación de QA probablemente requieren más esfuerzo que el desarrollo.
5. Tiene dependencias que impiden entregar una parte funcional sin esperar a todas las demás.
6. Combina objetivos que podrían validarse y desplegarse por separado.

No dividas solo por capas técnicas. Prioriza incrementos verticales de valor que puedan probarse de extremo a extremo o aislarse mediante mocks, stubs o feature flags.

### 5. Proponer la división

Cuando el ticket sea demasiado grande, propón subtareas que mantengan un resultado observable y criterios de aceptación propios. Usa, cuando corresponda, estas estrategias:

| Estrategia | Ejemplo de ticket grande | División recomendada |
| --- | --- | --- |
| Por flujo | Implementar checkout completo | Checkout básico / camino feliz; después errores y validaciones |
| Por regla o modo de negocio | Soportar varios medios de pago | Tarjeta; Pix o transferencia; otros modos |
| Por capacidad de configuración o UI | Crear pantalla de perfil completa | Visualización; edición y persistencia |
| Por feature flag o stub | Pantalla dependiente de backend no disponible | UI con mocks o stubs; integración con API real |

Cada subtarea propuesta debe indicar:

- objetivo único;
- alcance y fuera de alcance;
- dependencia explícita, si existe;
- criterios de aceptación verificables;
- forma de probarla e integrarla de manera independiente.

### 6. Cerrar la decisión

Antes de concluir, registrar cada nodo y sus relaciones padre/hijo con `workflow_state.py scope`, y ejecutar `workflow_state.py validate`. Si algún nodo queda `BLOCKED`, invocar `$entrevistar` dentro de esta fase, resolver una decisión por turno y volver a analizar el mismo nodo. Si un nodo requiere división, agregar sus hijos y analizar cada uno de forma recursiva. No concluir hasta que todos los nodos sean hojas `DONE` o exista un bloqueo explícito que requiera intervención del usuario.

El análisis completo solo puede marcarse como `CONFIRMED` cuando:

- el árbol tiene un nodo raíz válido;
- cada hijo referencia a su padre y cada padre referencia a sus hijos;
- cada nodo tiene título, estado y veredicto válidos;
- cada hoja está en `DONE` con veredicto `APTO_PARA_IMPLEMENTAR` y cada padre dividido está en `DONE` con veredicto `REQUIERE_DIVISION`;
- no existe ningún nodo `BLOCKED`, `PENDING` o `IN_PROGRESS`.

## Formato de salida

```markdown
## Veredicto de alcance

**Resultado:** APTO PARA IMPLEMENTAR / REQUIERE DIVISIÓN / BLOQUEADO
**Tamaño estimado:** 0.5–2 días / hasta 3 días / superior a 3 días / desconocido
**Motivo:** [conclusión breve]

## Checklist

- [PASS|FAIL|UNKNOWN] Independiente: [justificación]
- [PASS|FAIL|UNKNOWN] Pequeño: [justificación]
- [PASS|FAIL|UNKNOWN] Testeable: [justificación]
- [PASS|FAIL|UNKNOWN] Criterios de aceptación: [cantidad y calidad]
- [PASS|FAIL|UNKNOWN] Dependencias: [justificación]

## Señales detectadas

- [Señal o Ninguna]

## Subtareas propuestas

1. **[Título de subtarea]**
   - Objetivo: [resultado independiente]
   - Incluye: [alcance]
   - Excluye: [fuera de alcance]
   - Criterios de aceptación: [criterios verificables]
   - Dependencias: [dependencia o Ninguna]

## Riesgos y pendientes

- [Riesgo, supuesto o Ninguno]
```

## Reglas de calidad

- No uses solo una estimación temporal para aprobar o dividir un ticket.
- No dividas horizontalmente en tareas que no puedan probarse o entregar valor.
- Prefiere pocas subtareas verticales, independientes y testeables.
- Mantén las recomendaciones breves y accionables.
- Distingue hechos observados, inferencias y decisiones pendientes.
- No implementes cambios ni abras una PR.
