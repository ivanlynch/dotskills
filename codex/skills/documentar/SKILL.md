---
name: documentar
description: Redacta documentación técnica en español siguiendo Diátaxis. Úsala cuando el usuario quiera crear, reorganizar o mejorar un tutorial, una guía práctica, una referencia técnica o una explicación. Si el entregable principal es un README.md, deriva el trabajo a documentar-readme. Usa un flujo de descubrimiento inspirado en la skill cocinando: investiga los hechos disponibles, formula una sola pregunta por turno, recomienda una respuesta y espera confirmación antes de avanzar.
---

# Documentar con Diátaxis

Genera documentación clara, precisa, orientada al usuario y consistente con el contexto del proyecto. Clasifica cada documento en uno de los cuatro cuadrantes de Diátaxis y no mezcles objetivos incompatibles dentro de una misma pieza.

## Ruta especializada para README.md

Si el usuario pide crear, actualizar o mejorar un `README.md`, usa `$documentar-readme` como flujo especializado. Esa skill contiene las reglas específicas para revisar el proyecto, estructurar el README, usar GFM, incorporar admoniciones y detectar logos o iconos. Conserva el comportamiento de descubrimiento de `cocinando` para las decisiones que no puedan resolverse inspeccionando el entorno.

## Flujo de trabajo

### 1. Descubrimiento guiado

Antes de redactar, reúne la información necesaria. Si el usuario ya proporcionó un dato, no lo vuelvas a preguntar. Si el dato puede obtenerse del entorno, inspecciona archivos, estructura del proyecto o herramientas disponibles; no lo trates como una decisión del usuario.

Debes cerrar, como mínimo, estas decisiones:

- Tipo de documento: Tutorial, Guía práctica, Referencia o Explicación.
- Audiencia objetivo: por ejemplo, desarrolladores principiantes, administradores con experiencia o usuarios no técnicos.
- Objetivo del lector: qué debe poder entender o hacer al terminar.
- Alcance: temas incluidos y temas explícitamente excluidos.
- Contexto de publicación: archivo, sección del sitio, README, wiki u otro destino, si afecta la estructura.
- Restricciones relevantes: versión, idioma, tono, formato, ejemplos obligatorios, límites de extensión o requisitos de accesibilidad.

Aplica el modo de interrogación de `cocinando`:

1. Haz una sola pregunta breve por turno.
2. Después de cada pregunta, incluye una recomendación concreta y breve.
3. Espera la respuesta del usuario antes de hacer la siguiente pregunta.
4. Recorre dependencias en orden: tipo y audiencia antes que estructura; objetivo y alcance antes que ejemplos.
5. No redactes, crees archivos ni ejecutes cambios mientras sigan abiertas decisiones esenciales.
6. Cuando creas que el contexto está completo, presenta un resumen de entendimiento compartido y pide confirmación explícita.

No conviertas esta fase en un cuestionario. Prioriza la pregunta que desbloquee más decisiones. Si el usuario dice que no sabe, ofrece dos o tres opciones y recomienda una.

### 2. Propuesta de estructura

Tras la confirmación del entendimiento compartido, propone un índice detallado. Para cada sección, explica en una frase qué logrará el lector o qué información contendrá. La estructura debe corresponder al tipo elegido:

- **Tutorial:** recorrido de aprendizaje, con pasos progresivos y un resultado verificable.
- **Guía práctica:** receta para resolver un problema concreto, con precondiciones y comprobación del resultado.
- **Referencia:** descripción exhaustiva y neutral de comandos, opciones, parámetros, estados, errores o APIs.
- **Explicación:** modelo mental, contexto, decisiones de diseño, causas, consecuencias y límites.

Indica también qué quedará fuera. Espera la aprobación del índice antes de escribir el contenido completo. Si el usuario pide cambios, ajusta la propuesta y vuelve a pedir aprobación.

### 3. Redacción

Cuando el índice esté aprobado, redacta en Markdown y en español, salvo que el usuario pida otro idioma. Sigue estas reglas:

- Empieza por el propósito y el resultado esperado.
- Escribe para la audiencia acordada, con lenguaje simple, directo y sin ambigüedad.
- Mantén una terminología estable; define los términos necesarios en su primera aparición.
- Distingue instrucciones, información, advertencias, ejemplos y resultados esperados.
- Usa bloques de código ejecutables y coherentes con las versiones indicadas.
- No inventes APIs, comandos, salidas, rutas, versiones ni comportamiento. Marca como pendiente cualquier dato no verificado.
- Usa el contexto Markdown entregado por el usuario para imitar tono y terminología, pero no copies contenido salvo autorización explícita.
- No consultes sitios externos ni otras fuentes por iniciativa propia. Solo usa un enlace o fuente externa cuando el usuario la proporcione y autorice expresamente su consulta.
- Evita rellenar el documento con contenido de otro cuadrante: una guía puede enlazar a una referencia, pero no reemplazarla.

### 4. Revisión

Antes de entregar, verifica:

- que el documento cumple el objetivo del lector;
- que el tipo de Diátaxis se mantiene de principio a fin;
- que no quedan decisiones esenciales sin resolver;
- que los pasos están ordenados y tienen precondiciones y resultados verificables cuando corresponde;
- que los ejemplos y fragmentos de código son consistentes con el contexto disponible;
- que los términos, encabezados, enlaces y formato Markdown son consistentes;
- que las incertidumbres están señaladas en vez de presentarse como hechos.

Si faltan datos después de comenzar la redacción, pausa y vuelve al descubrimiento guiado con una sola pregunta.

## Formato de interacción

Durante el descubrimiento:

```text
Pregunta: [una sola decisión concreta]
Recomendación: [opción sugerida y motivo breve]
```

Al cerrar el descubrimiento:

```text
Entendimiento compartido:
- Tipo: ...
- Audiencia: ...
- Objetivo: ...
- Alcance: ...
- Fuera de alcance: ...
- Restricciones: ...

¿Confirmas este entendimiento para que proponga la estructura?
```

Al proponer el índice, termina con una solicitud explícita de aprobación. No generes el documento completo hasta recibirla.
