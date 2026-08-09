---
name: clasificar-documentacion
description: Clasifica una solicitud documental según las necesidades del usuario y los fundamentos de Diátaxis. Úsala dentro de documentar antes de delegar en tutoriales, guías prácticas, referencia o explicaciones.
---

# Clasificar documentación

Determina el cuadrante documental dominante antes de redactar. No clasifiques por el nombre que el usuario dé al documento, sino por la necesidad que debe atender.

## Fundamentos de Diátaxis

Analiza dos dimensiones:

- **Relación con la habilidad:** el usuario la está adquiriendo o aplicando.
- **Necesidad inmediata:** necesita actuar o comprender.

| Situación | Necesidad | Cuadrante |
| --- | --- | --- |
| Adquirir una habilidad | Actuar y aprender haciendo | Tutorial |
| Aplicar una habilidad | Actuar para lograr una tarea | Guía práctica |
| Aplicar conocimiento | Consultar información mientras trabaja | Referencia |
| Adquirir conocimiento | Comprender conceptos y relaciones | Explicación |

Un documento debe tener un propósito dominante. Identifica otros cuadrantes como documentación relacionada, pero no los mezcles dentro de la pieza principal.

## Procedimiento

1. Lee la solicitud, el contexto y los artefactos disponibles.
2. Separa hechos comprobables, decisiones del usuario e inferencias.
3. Determina si el usuario está estudiando o trabajando.
4. Determina si está adquiriendo o aplicando una habilidad.
5. Determina si necesita actuar o comprender.
6. Selecciona el cuadrante que mejor satisface la necesidad dominante.
7. Registra la justificación y las evidencias.
8. Evalúa la certeza como `alta`, `media` o `baja`.
9. Si falta una decisión esencial o la certeza es baja, formula una sola pregunta breve, incluye una recomendación y espera respuesta.

No redactes ni delegues mientras falte información esencial.

## Salida

Devuelve:

```yaml
cuadrante: tutorial | guia-practica | referencia | explicacion
justificacion:
  estado_usuario: estudio | trabajo
  relacion_con_habilidad: adquisicion | aplicacion
  necesidad: accion | cognicion
certeza: alta | media | baja
evidencias: []
informacion_faltante: []
documentacion_relacionada: []
```

La salida debe explicar por qué el cuadrante elegido sirve a la necesidad actual y no solo describir la forma prevista del documento.
