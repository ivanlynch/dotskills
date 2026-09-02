# Reglas de Split.io

## Nombre

Usar `ze_consumer_{{tipo}}_{{feature_name}}`, donde `tipo` es `rollout`, `ab` o `kill`.

Aplicar minúsculas, `snake_case`, ASCII, nombres descriptivos y preferentemente orientados a acción (`enable_`, `use_`, `block_`). No incluir ambientes ni términos genéricos. Mantener el nombre idealmente en 60 caracteres o menos.

## Metadata obligatoria

La descripción debe incluir:

- Propósito: qué controla la flag y qué problema resuelve.
- Alcance: servicios, rutas, pantallas o componentes afectados.
- Fallback: comportamiento con flag apagada o SDK indisponible.
- Métrica(s) principal(es), especialmente para experimentos.
- Criterio de desligamiento: cuándo y cómo remover código y flag, incluyendo fecha prevista si existe.

Añadir el tag de equipo con formato `dtc-consumer-{{nome-do-time}}`.

## A/B

Usar exclusivamente valores `control_1`, `control_2`, ... para controles y `variant_a`, `variant_b`, ... para variantes. Documentar el significado de cada valor en la descripción, además de la métrica primaria, duración objetivo y enlace de la tarea.

No reutilizar una flag para otro propósito. No usar la misma flag A/B en frontend y backend. No usar Split.io como almacenamiento de configuración dinámica.

## Ciclo de vida

Crear una tarea de cleanup al crear la flag. Remover código y flag hasta dos sprints después de alcanzar el rollout completo o concluir el experimento. Revisar flags activas periódicamente.
