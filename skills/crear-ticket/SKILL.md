---
name: crear-ticket
description: Entrevista al usuario hasta alcanzar un entendimiento objetivo, claro y sin ambigüedades, y genera el título y la descripción de un ticket de Jira listo para copiar. Adapta la estructura a una User Story, Task o Bug, con contexto de negocio, intención, criterios de aceptación y consideraciones técnicas. Usar cuando el usuario quiera redactar, definir o preparar un ticket de Jira antes de crearlo.
---

# Crear Ticket

Genera el contenido de un ticket de Jira equilibrando claridad para desarrollo, contexto de negocio y criterios explícitos de éxito. El resultado incluye un título conciso y una descripción completa, pero no crea ni modifica tickets en Jira.

## Idioma de salida

La salida final del ticket debe estar siempre en portugués de Brasil (`pt-BR`), incluyendo el título, el contexto, la User Story, los criterios de aceptación, los detalles técnicos y la evidencia de Bugs. La entrevista puede seguir el idioma de la conversación para facilitar el intercambio, pero el resultado final debe traducirse y redactarse naturalmente en `pt-BR`, sin traducciones literales extrañas.

## Regla principal: entrevistar antes de redactar

Usa el skill global `/entrevistar` como parte obligatoria del flujo:

1. Haz una sola pregunta por turno.
2. Mantén cada pregunta breve y directa.
3. Incluye una recomendación concreta después de cada pregunta.
4. Espera la respuesta antes de formular la siguiente pregunta.
5. Investiga hechos disponibles en el workspace o en el contexto proporcionado en lugar de preguntarlos.
6. Plantea al usuario las decisiones, preferencias y supuestos que no puedan descubrirse.
7. No redactes el ticket final hasta alcanzar un entendimiento compartido y pedir confirmación explícita.

No conviertas la entrevista en un formulario rígido. Prioriza la pregunta que elimine la ambigüedad más importante y recorre las dependencias en orden.

## Información que debes cerrar

Antes de presentar el resultado final, confirma o resuelve:

- **Tipo de ticket:** User Story, Task o Bug.
- **Módulo o componente:** área impactada, evitando nombres inventados.
- **Objetivo o problema:** qué se necesita cambiar o qué está fallando.
- **Usuario, sistema o rol afectado:** quién realiza la acción o recibe el beneficio.
- **Motivación:** por qué es necesario y qué impacto tiene.
- **Alcance:** qué debe incluir y qué queda fuera.
- **Criterios de aceptación:** cómo se verifica que el ticket está terminado.
- **Detalles técnicos:** APIs, endpoints, módulos, datos, reglas de arquitectura, compatibilidad y accesibilidad, solo cuando sean relevantes.
- **Diseño y recursos:** Figma, RFC, documentación, capturas, logs o enlaces disponibles.
- **Dependencias y restricciones:** otros tickets, equipos, plataformas, ambientes, fechas o riesgos.

Si el usuario desconoce un dato, ofrece dos o tres alternativas y recomienda una. Si el dato no es esencial, decláralo como supuesto o `No definido` en lugar de bloquear todo el flujo.

## Orden recomendado de la entrevista

Adapta las preguntas al contexto, pero normalmente sigue este orden:

1. Identificar si es una User Story, Task o Bug.
2. Cerrar el módulo o componente y el objetivo principal.
3. Entender el contexto de negocio o la causa técnica.
4. Definir quién interactúa con el sistema y cuál es el beneficio esperado.
5. Delimitar el alcance y el fuera de alcance.
6. Convertir el resultado esperado en criterios de aceptación verificables.
7. Confirmar detalles técnicos, recursos y dependencias.
8. Resumir el entendimiento compartido y pedir confirmación.

Si se trata de un Bug, prioriza la reproducibilidad: entorno, pasos, comportamiento esperado, comportamiento actual y evidencia.

## Formato de interacción durante la entrevista

Usa este formato, sin hacer varias preguntas a la vez:

```text
Pregunta: [una decisión o dato concreto]
Recomendación: [opción sugerida y motivo breve]
```

Cuando toda la información esencial esté cerrada, presenta:

```text
Entendimento compartilhado:
- Tipo de ticket: ...
- Módulo ou componente: ...
- Objetivo ou problema: ...
- Escopo: ...
- Fora do escopo: ...
- Critérios de sucesso: ...
- Suposições e pendências: ...

Você confirma este entendimento para que eu gere o título e a descrição final?
```

Espera la confirmación. Si el usuario corrige algo, actualiza el entendimiento y vuelve a pedir confirmación.

## Formato de salida final

Después de la confirmación, entrega únicamente un ticket listo para copiar, salvo que el usuario pida una explicación adicional.

### User Story ou Task

```markdown
## Título

[Módulo/Componente]: Breve descrição do objetivo

## Contexto ou declaração do problema

[Razão de negócio ou problema técnico que motiva a tarefa. Explique por que ela é necessária.]

## Descrição / User Story

**Como** [papel do usuário / sistema],
**quero** [ação ou funcionalidade],
**para** [benefício de negócio ou objetivo].

## Critérios de aceitação

- **Dado que** [pré-condição], **quando** [ação], **então** [resultado verificável].
- [ ] [Critério adicional verificável]
- [ ] [Critério adicional verificável]

## Detalhes técnicos e considerações

- **Endpoints / APIs envolvidas:** [detalhe ou Não se aplica]
- **Módulos / domínio:** [detalhe ou Não se aplica]
- **Acessibilidade:** [requisito ou Não se aplica]
- **Dependências e restrições:** [detalhe ou Não se aplica]

## Design / recursos

- **Figma:** [link ou Não se aplica]
- **Documentação / RFC:** [link ou Não se aplica]
- **Outros recursos:** [link, captura, log ou Não se aplica]
```

### Bug

Para um Bug, substitua a estrutura anterior por:

```markdown
## Título

[Módulo/Componente]: Corrigir [comportamento defeituoso]

## 🐛 Descrição do bug

[Resumo da falha e ambiente: Staging/Production, iOS/Android, versão ou outro dado relevante.]

## 🔄 Passos para reproduzir

1. [Passo reproduzível]
2. [Passo reproduzível]
3. [Passo reproduzível]

## 🎯 Comportamento esperado

[O que deveria acontecer.]

## 💥 Comportamento atual

[O que acontece atualmente.]

## ✅ Critérios de aceitação

- [ ] O cenário que reproduzia o erro funciona conforme o comportamento esperado.
- [ ] Nenhuma regressão é introduzida nos cenários relacionados.
- [ ] [Critério adicional verificável]

## 📷 Evidências / logs

- [Captura, vídeo, log ou stack trace; use Não se aplica se não existir.]

## Detalhes técnicos e recursos

- **Módulo / domínio:** [detalhe ou Não se aplica]
- **Dependências e restrições:** [detalhe ou Não se aplica]
- **Documentação / RFC / Figma:** [link ou Não se aplica]
```

## Regras de qualidade

- O título deve comunicar exatamente o que a tarefa faz: a ação, o componente afetado e, quando necessário, o resultado esperado. Deve ser conciso e ter aproximadamente seis a sete palavras em média. Essa é uma orientação flexível: nomes próprios, termos técnicos ou informações indispensáveis podem aumentar ou reduzir a contagem quando necessário para preservar a clareza. Evite títulos vagos, genéricos ou que exijam interpretação adicional.
- La descrição deve explicar o `porquê`, o `quê`, o `quem` e o resultado esperado.
- Os critérios de aceitação devem ser verificáveis por desenvolvimento e QA.
- Prefira Given-When-Then quando o comportamento tiver pré-condições e eventos claros; use checklist para validações independentes.
- Não invente endpoints, módulos, estados, versões, links, logs ou requisitos.
- Use `Não se aplica` somente depois de determinar que a seção não é pertinente.
- Não preencha a descrição com metadados que o Jira já possui como campos nativos: Components, Labels ou Fix Version.
- Se o ticket parecer exigir mais de três a cinco dias de desenvolvimento ou abranger domínios independentes, recomende dividi-lo em subtarefas ou tickets menores.
- Mantenha um único objetivo principal por ticket.
- Não inclua detalhes de implementação desnecessários quando o resultado puder ser expresso como comportamento verificável.

## Resultado e revisão

Antes de entregar, verifica que:

- o tipo de ticket e o modelo escolhido coincidem;
- o objetivo pode ser expresso em uma única frase clara;
- o escopo e o que está fora do escopo não se contradizem;
- cada critério de aceitação tem um resultado verificável;
- não restam decisões essenciais ambíguas;
- os dados desconhecidos estão marcados como suposições, pendências ou `Não se aplica`.
