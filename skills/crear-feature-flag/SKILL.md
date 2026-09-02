---
name: crear-feature-flag
description: Obtener un ticket de Jira por ID mediante la API REST y generar una propuesta completa de feature flag de Split.io, incluyendo nombre, tipo, targeting, fallback, métricas, criterio de limpieza y tag de equipo. Usar cuando el usuario pida crear, nombrar o documentar una feature flag a partir de un ticket Jira, por ejemplo `$crear-feature-flag DTCZE-1234`.
---

# Crear una feature flag

Ejecutar el flujo siguiente con un único ID de Jira recibido como argumento.

## 1. Validar el ticket

- Aceptar exactamente un ID con formato `^[A-Z][A-Z0-9]+-[0-9]+$`; normalizarlo a mayúsculas.
- Invocar `$consultar-ticket <TICKET_ID>` para obtener el título y la descripción mediante la implementación común de Jira.
- Si `$consultar-ticket` se detiene por autenticación, esperar a que complete su flujo de configuración y confirmación antes de continuar. No duplicar ni saltarse ese flujo.
- Usar como fuente de verdad el título y la descripción devueltos por `$consultar-ticket`. No inventar datos ausentes.

## 2. Clasificar el tipo de flag

Leer [split-guidelines.md](references/split-guidelines.md) antes de generar la propuesta.

- `rollout`: lanzamiento gradual o habilitación controlada de una funcionalidad.
- `ab`: experimento A/B con variantes explícitas.
- `kill`: apagado de una funcionalidad crítica con riesgo real.

No usar `kill` como sinónimo de fallback ni para una funcionalidad no crítica. Si el ticket no permite distinguir el tipo, marcar la propuesta como `BLOQUEADA` y pedir una sola decisión al usuario.

## 3. Generar el nombre

Aplicar exactamente:

```text
ze_consumer_{{tipo}}_{{feature_name}}
```

El nombre debe usar únicamente ASCII, minúsculas y `snake_case`, comenzar con un verbo cuando sea natural, ser descriptivo, no incluir ambiente y tener idealmente como máximo 60 caracteres. No usar `tmp`, `test`, `new`, `foo`, `bar`, `on`, `off`, `true` o `false` como nombre.

Si el nombre derivado supera 60 caracteres, proponer una versión más corta sin perder el propósito y señalar la reducción. No crear nombres basados solo en el ID del ticket.

## 4. Generar la configuración

Producir una propuesta lista para copiar en Split.io con:

- ID y título de Jira, enlace al ticket y resumen de la intención.
- Nombre de la flag y tipo.
- Descripción con propósito, alcance, fallback, métricas principales y criterio de desligamiento/limpieza con fecha estimada si el ticket la define.
- Targeting inicial y atributos requeridos, únicamente cuando estén respaldados por el ticket. No inventar segmentos.
- Tag `dtc-consumer-{{nome-do-time}}`, derivada del equipo explícito del ticket; si no existe, pedir el nombre del equipo en vez de inventarlo.
- Para `ab`, variantes solo con `control_1`, `control_2`, ... y `variant_a`, `variant_b`, ...; describir qué representa cada una, la métrica primaria y la duración objetivo. Nunca usar `on/off`, `true/false`, `A/B` o `test/control` como valores.
- Dependencias, riesgos y tarea de cleanup mencionada en el ticket o claramente pendiente.

## 5. Responder

Responder en español, manteniendo los nombres de Split en inglés y el idioma original de los textos funcionales cuando sea necesario. Usar este formato breve:

```text
Estado: READY | BLOQUEADA
Ticket: <ID> — <título>
Flag: <nombre>
Tipo: <rollout|ab|kill>
Targeting: <reglas o “no definido en Jira”>
Tag: <tag o “pendiente: falta equipo”>

Descripción para Split.io:
<texto listo para pegar>

Validaciones:
- Nomenclatura: PASS/FAIL
- Metadatos obligatorios: PASS/FAIL
- Variantes: PASS/N/A/FAIL

Pendientes o decisiones:
- <solo los que existan>
```

No modificar código del repositorio, no crear la flag remotamente y no activar rollout. Esta skill genera una propuesta; la creación/publicación en Split.io requiere una acción separada y autorización explícita.
