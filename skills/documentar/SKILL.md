---
name: documentar
description: Orquesta la creación, reorganización o mejora de documentación técnica en español con Diátaxis. Clasifica la necesidad del lector, exige fuentes verificables, redacta según el cuadrante dominante y audita el resultado antes de entregarlo.
---

# Documentar con Diátaxis

Genera documentación clara, precisa, orientada al usuario y consistente con la evidencia disponible. Elige el cuadrante por la necesidad del lector, no por el nombre del archivo ni por el formato solicitado. Mantén un propósito dominante por pieza y deriva las necesidades relacionadas a documentación separada.

## Fundamentos de Diátaxis

Diátaxis organiza la documentación a partir de dos dimensiones:

- **Adquisición o aplicación:** el usuario está aprendiendo una habilidad o utilizándola.
- **Acción o cognición:** necesita hacer algo o comprender algo.

La combinación determina el cuadrante:

| Situación del usuario | Necesidad principal | Cuadrante |
| --- | --- | --- |
| Adquiere una habilidad | Actuar y aprender haciendo | Tutorial |
| Aplica una habilidad | Actuar para lograr una tarea | Guía práctica |
| Aplica conocimiento | Consultar información mientras trabaja | Referencia |
| Adquiere conocimiento | Comprender conceptos y relaciones | Explicación |

El usuario puede entrar en cualquier cuadrante y moverse entre ellos. No impongas la secuencia tutorial → guía → referencia → explicación. La clasificación sirve para preservar el propósito de cada pieza y evitar que los cuadrantes se desdibujen.

### Tutorial

Sirve al usuario que está estudiando mediante la práctica. Proporciona una experiencia de aprendizaje controlada, concreta, segura, reproducible y progresiva. Prepara el entorno, reduce decisiones innecesarias y conduce a un resultado verificable. No se define por ser básico: también puede enseñar una habilidad avanzada.

### Guía práctica

Sirve al usuario que está trabajando y necesita completar una tarea real. Se orienta a un objetivo, explicita precondiciones, contempla variantes y prepara para lo inesperado. Puede ramificarse y ofrecer rutas alternativas. No se define por ser avanzada: también puede describir una tarea básica.

### Referencia

Sirve al usuario que consulta información mientras trabaja. Describe la maquinaria con precisión, neutralidad y cobertura suficiente: comandos, APIs, opciones, parámetros, estados, errores o compatibilidades. Usa listas, tablas y ejemplos mínimos. No se convierte en tutorial ni explicación discursiva.

### Explicación

Sirve al usuario que está adquiriendo comprensión. Desarrolla modelos mentales, contexto, causas, relaciones, decisiones, consecuencias, alternativas y límites. Distingue hechos de interpretaciones. No se convierte en una guía de pasos ni en una referencia exhaustiva.

## Flujo de trabajo

### 1. Descubrimiento guiado

Antes de redactar, reúne la información necesaria. Investiga los hechos que puedan obtenerse del contexto y pregunta solo las decisiones que correspondan al usuario.

Para documentación de un proyecto o tarea, inspecciona primero:

- proyecto y branch actual;
- código y estructura;
- configuración y manifiestos;
- pruebas y scripts;
- historial relevante;
- documentación y ejemplos existentes;
- versiones, variables y restricciones documentadas.

Debes cerrar, como mínimo:

- necesidad del usuario y estado de estudio o trabajo;
- audiencia;
- objetivo del lector;
- alcance y exclusiones;
- destino de publicación;
- versión, idioma, tono, formato y restricciones;
- resultado verificable.

Separa siempre:

- **Hechos:** comprobables en el contexto o en una fuente autorizada.
- **Decisiones:** elegidas explícitamente por el usuario.
- **Inferencias:** conclusiones derivadas, que deben etiquetarse como tales.

Aplica el modo de entrevista de `/entrevistar`:

1. Formula una sola pregunta breve por turno.
2. Incluye una recomendación concreta y breve.
3. Espera la respuesta antes de continuar.
4. Resuelve primero las decisiones de las que dependen las demás.
5. No redactes mientras falte una decisión esencial.
6. Cuando el contexto esté completo, presenta un entendimiento compartido y pide confirmación.

No conviertas la fase en un cuestionario. Si una respuesta es un hecho verificable, investígala en lugar de preguntarla.

### 2. Clasificación del cuadrante

Determina explícitamente:

1. ¿El usuario está estudiando o trabajando?
2. ¿Está adquiriendo o aplicando una habilidad?
3. ¿Necesita actuar o comprender?
4. ¿Cuál es la necesidad dominante?

Clasifica así:

```text
adquirir + actuar      → tutorial
aplicar + actuar       → guía práctica
aplicar + comprender   → referencia
adquirir + comprender  → explicación
```

No clasifiques por palabras como “manual”, “guía”, “documentación” o “README”. Si el contexto no permite decidir con seguridad, formula una sola pregunta y espera. Registra la justificación, las evidencias y la información faltante.

Un documento puede tener documentación relacionada de otros cuadrantes, pero debe conservar un cuadrante dominante. Usa enlaces o piezas separadas en vez de absorber sus objetivos.

### 3. Política de fuentes

Toda afirmación relevante debe ser comprobable y tener una fuente trazable.

Para proyectos y tareas:

1. Busca primero en el proyecto y la branch actual.
2. Prioriza código, configuración, pruebas, scripts, historial y documentación local.
3. Registra el archivo, símbolo, prueba o commit que respalda cada afirmación.

Para otros tipos de documentación:

1. Busca en Internet cuando el contexto local no sea la fuente adecuada.
2. Prioriza documentación oficial y fuentes primarias.
3. Registra URL, título, sección consultada y fecha de verificación.
4. Presenta al usuario las fuentes centrales.
5. Espera su aprobación antes de usar esas fuentes para afirmaciones centrales.

No uses fuentes secundarias salvo autorización expresa. Si una fuente externa contradice el comportamiento comprobado de un proyecto, señala la discrepancia y prioriza el comportamiento observado del proyecto para documentarlo.

Si no existe una fuente verificable:

- investiga el entorno si es un hecho local;
- pregunta al usuario si es una decisión;
- marca el dato como pendiente si no puede verificarse;
- nunca lo presentes como un hecho confirmado.

### 4. Entendimiento y estructura

Después de clasificar la necesidad y cerrar las fuentes, presenta:

```text
Entendimiento compartido:
- Cuadrante dominante: ...
- Audiencia: ...
- Objetivo: ...
- Alcance: ...
- Fuera de alcance: ...
- Fuentes aprobadas: ...
- Restricciones: ...

¿Confirmas este entendimiento para que proponga la estructura?
```

Tras la confirmación, propone un índice detallado. Explica en una frase qué logrará el lector o qué información contendrá cada sección. La estructura debe corresponder al cuadrante:

- **Tutorial:** lección práctica, secuencia controlada y resultado verificable.
- **Guía práctica:** objetivo, precondiciones, pasos, variantes y comprobación.
- **Referencia:** superficie técnica, organización navegable y descripciones neutrales.
- **Explicación:** modelo mental, contexto, causas, consecuencias y límites.

Indica qué quedará fuera y espera aprobación del índice antes de redactar el contenido completo.

### 5. Redacción

Cuando el índice esté aprobado, redacta en Markdown y en español, salvo indicación contraria. Sigue estas reglas:

- empieza por el propósito y el resultado esperado;
- escribe para la audiencia acordada;
- mantén una terminología estable;
- distingue instrucciones, información, advertencias, ejemplos y resultados;
- usa bloques de código coherentes con las versiones verificadas;
- incluye fuentes relevantes mediante enlaces, notas o referencias;
- separa hechos, decisiones e inferencias;
- no inventes APIs, comandos, salidas, rutas, versiones ni comportamiento;
- marca como pendiente cualquier dato no verificado;
- enlaza otros cuadrantes en vez de reemplazarlos.

### 6. Auditoría independiente

Cuando exista un borrador, lanza un subagente auditor independiente o realiza un pase de auditoría separado si el entorno no permite delegarlo. El auditor debe recibir el documento, el cuadrante, el contexto, las fuentes y las decisiones del usuario.

El auditor no redacta ni corrige. Debe comprobar:

- cada afirmación factual y su fuente;
- comandos, rutas, APIs, versiones, enlaces y ejemplos;
- coherencia con el proyecto y la branch;
- separación entre hechos, decisiones e inferencias;
- exactitud, completitud, consistencia, utilidad y precisión;
- propósito dominante y límites del cuadrante;
- flujo, claridad, anticipación y experiencia del lector.

Clasifica los hallazgos:

- **Bloqueante:** afirmación sin respaldo, contradicción con el contexto, comando no comprobable o defecto que impide cumplir el propósito.
- **Importante:** evidencia incompleta, ambigüedad relevante, paso sin comprobación o mezcla significativa de cuadrantes.
- **Menor:** mejora editorial, formato, terminología o enlace que no afecta la validez.

Usa este formato:

```yaml
estado: aprobado | requiere-cambios | bloqueado
hallazgos:
  - severidad: bloqueante | importante | menor
    ubicacion: "seccion o linea"
    problema: "..."
    evidencia: "..."
    recomendacion: "..."
fuentes_validadas: []
fuentes_faltantes: []
cuadrante_validado: true | false
```

### 7. Corrección y cierre

Si hay hallazgos bloqueantes o importantes:

1. Corrige el documento usando fuentes disponibles.
2. Si falta un dato o una decisión, formula una sola pregunta al usuario.
3. Si falta una fuente externa central, solicita su aprobación.
4. Vuelve a auditar después de cada corrección relevante.

Continúa hasta reunir toda la información necesaria y obtener `estado: aprobado`. No establezcas un límite fijo de rondas ni inventes información para salir del ciclo.

Entrega solo cuando:

- el cuadrante dominante está justificado;
- el objetivo del lector se cumple;
- las afirmaciones relevantes tienen fuentes trazables;
- los ejemplos y comandos están comprobados;
- no hay decisiones esenciales abiertas;
- no hay hallazgos bloqueantes ni importantes;
- el documento conserva el flujo y propósito de su cuadrante.

Entrega las fuentes relevantes junto con el documento y resume los hallazgos de la auditoría. Conserva los detalles necesarios para reconstruir qué se comprobó y con qué evidencia.
