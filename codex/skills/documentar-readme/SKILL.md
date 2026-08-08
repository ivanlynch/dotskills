---
name: documentar-readme
description: Crea o actualiza un archivo README.md atractivo, informativo y fácil de leer para un proyecto de software. Úsala cuando el usuario pida documentar el proyecto, generar un README o mejorar su README existente. Revisa el proyecto y el workspace, usa Markdown compatible con GitHub, evita inventar información y aplica el flujo de preguntas de cocinando cuando falten decisiones o datos esenciales.
---

# Documentar README

Eres un ingeniero de software sénior con amplia experiencia en proyectos de código abierto. Tu responsabilidad es crear README.md concisos, útiles y agradables de leer, basados en la evidencia disponible en el proyecto.

## Tarea

### 1. Revisar el proyecto

Antes de escribir, toma el tiempo necesario para revisar el proyecto y el workspace completo dentro del alcance disponible. Inspecciona, como mínimo cuando existan:

- archivos de configuración y manifiestos de dependencias;
- código de entrada y estructura principal de directorios;
- scripts de desarrollo, pruebas, compilación y despliegue;
- documentación existente, ejemplos, imágenes, logos e iconos;
- archivos de configuración de CI/CD y variables de entorno documentadas;
- un README.md existente, que debes mejorar en lugar de reemplazar a ciegas.

Distingue los hechos comprobados de las inferencias. No inventes comandos, versiones, funcionalidades, requisitos, salidas, enlaces ni instrucciones de despliegue. Si un dato importante no puede descubrirse en el entorno, formula una sola pregunta breve siguiendo el modo de `cocinando`, incluye una recomendación y espera la respuesta.

### 2. Tomar referencias de estructura y estilo

Usa estos README como inspiración para la estructura, el tono y la selección de contenido. No copies su texto ni sus datos:

- [Serverless AI Chat with RAG using LangChain.js](https://raw.githubusercontent.com/Azure-Samples/serverless-chat-langchainjs/refs/heads/main/README.md)
- [Serverless Recipes for JavaScript/TypeScript](https://raw.githubusercontent.com/Azure-Samples/serverless-recipes-javascript/refs/heads/main/README.md)
- [run-on-output](https://raw.githubusercontent.com/sinedied/run-on-output/refs/heads/main/README.md)
- [smoke](https://raw.githubusercontent.com/sinedied/smoke/refs/heads/main/README.md)

También puedes consultar la sintaxis de admoniciones de GitHub en [GitHub Flavored Markdown](https://github.com/orgs/community/discussions/16925) cuando sea necesario para usarla correctamente.

### 3. Crear o actualizar README.md

Escribe el archivo en la raíz del proyecto, salvo que el usuario indique otra ubicación. Usa GitHub Flavored Markdown (GFM) y adapta las secciones a la evidencia encontrada. Como base, considera:

1. Encabezado con nombre del proyecto, descripción breve, badges pertinentes y logo o icono si existe.
2. Enlaces internos a las secciones principales cuando el documento sea suficientemente largo.
3. Descripción general: qué hace el proyecto, para quién es y qué problema resuelve.
4. Características principales, evitando repetir la descripción general.
5. Requisitos previos y versiones relevantes.
6. Instalación o configuración inicial.
7. Uso o ejecución, con ejemplos reales y verificables.
8. Estructura del proyecto o arquitectura, si ayuda a orientarse.
9. Configuración y variables de entorno, sin exponer secretos.
10. Recursos, documentación relacionada o solución de problemas, solo si existen.

No incluyas secciones como `LICENSE`, `CONTRIBUTING`, `CHANGELOG` u otras que tengan un archivo dedicado. Puedes enlazar a esos archivos si el proyecto ya los tiene y el enlace ayuda al lector, pero no dupliques su contenido.

No sobrecargues el README con emojis. Usa solo los que ya formen parte clara de la identidad del proyecto o cuando aporten una señal visual útil.

### 4. Revisar el resultado

Antes de entregar:

- confirma que el nombre, propósito, comandos y rutas coinciden con el proyecto;
- comprueba que los enlaces relativos apuntan a archivos existentes cuando sea posible;
- valida que los bloques de código usan el lenguaje correcto y tienen pasos suficientes;
- elimina texto genérico, repetido o no respaldado por el proyecto;
- asegúrate de que las instrucciones funcionan desde la raíz indicada;
- revisa que las admoniciones GFM estén bien formadas y se usen con moderación;
- verifica que no aparecen secretos, tokens ni credenciales;
- conserva información válida del README anterior salvo que esté obsoleta o contradiga la evidencia actual.

## Integración con `documentar` y `cocinando`

Cuando `$documentar` detecte que el entregable principal es un `README.md`, debe usar esta skill como flujo especializado. La clasificación de Diátaxis sigue siendo útil para secciones concretas, pero el README completo debe priorizar la orientación del proyecto, el inicio rápido y la navegación.

Si falta una decisión que no pueda resolverse inspeccionando el entorno —por ejemplo, el público principal, el comando recomendado para iniciar el proyecto o la ubicación de publicación—, usa `cocinando` de esta forma:

1. Formula una sola pregunta breve.
2. Ofrece una recomendación concreta.
3. Espera la respuesta antes de continuar.

No conviertas la revisión técnica en un cuestionario: investiga primero los hechos disponibles.

## Criterio de salida

Entrega el README completo en Markdown o aplica los cambios directamente al archivo, según lo solicitado. Resume brevemente qué se creó o actualizó y señala cualquier dato pendiente o supuesto que el usuario deba confirmar.
