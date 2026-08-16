<!--
  Plantilla del veredicto final de analizar-alcance.

  Cómo usarla:
  1. Copiar este archivo al path que devuelve
     `workflow_state.py verdict-path <ID>` (no editar este archivo original).
  2. Reemplazar cada token {{TOKEN}} por contenido real. No dejar ningún
     {{TOKEN}} sin completar: `workflow_state.py check-verdict <ID>` falla
     si detecta alguno.
  3. El bloque "Subtareas propuestas" es repetible: duplicarlo una vez por
     cada work item hijo cuando el veredicto raíz sea REQUIERE DIVISIÓN.
     Si el veredicto raíz es APTO PARA IMPLEMENTAR, borrar el bloque de
     ejemplo y dejar únicamente la línea "Ninguna" bajo el encabezado.
  4. Borrar este comentario antes de considerar el archivo terminado (si
     queda, no bloquea check-verdict, pero no debe llegar al usuario).
-->

## Veredicto de alcance

**Resultado:** {{RESULTADO}}
**Tamaño estimado:** {{TAMANO_ESTIMADO}}
**Motivo:** {{MOTIVO}}

## Checklist

- [{{INDEPENDIENTE_VEREDICTO}}] Independiente: {{INDEPENDIENTE_JUSTIFICACION}}
- [{{PEQUENO_VEREDICTO}}] Pequeño: {{PEQUENO_JUSTIFICACION}}
- [{{TESTEABLE_VEREDICTO}}] Testeable: {{TESTEABLE_JUSTIFICACION}}
- [{{CRITERIOS_VEREDICTO}}] Criterios de aceptación: {{CRITERIOS_JUSTIFICACION}}
- [{{DEPENDENCIAS_VEREDICTO}}] Dependencias: {{DEPENDENCIAS_JUSTIFICACION}}

## Señales detectadas

- {{SENALES}}

## Subtareas propuestas

1. **{{SUBTAREA_TITULO}}**
   - Objetivo: {{SUBTAREA_OBJETIVO}}
   - Incluye: {{SUBTAREA_INCLUYE}}
   - Excluye: {{SUBTAREA_EXCLUYE}}
   - Criterios de aceptación: {{SUBTAREA_CRITERIOS}}
   - Dependencias: {{SUBTAREA_DEPENDENCIAS}}

## Riesgos y pendientes

- {{RIESGOS}}
