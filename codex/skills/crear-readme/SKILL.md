---
name: crear-readme
description: Genera archivos README.md completos y profesionales para proyectos de software mediante el análisis de la estructura del proyecto, sus dependencias y sus patrones de código. Úsala cuando el usuario pida crear un README.md o generar documentación inicial para un proyecto.
---

# Crear README

Genera automáticamente archivos `README.md` profesionales y completos mediante el análisis de la estructura, las dependencias y los patrones de código del proyecto.

## Qué hace esta skill

Ayuda a crear README de alta calidad mediante:

- el análisis de la estructura del proyecto y la identificación de sus componentes principales;
- la detección de lenguajes de programación y frameworks;
- la búsqueda de archivos de configuración (`package.json`, `requirements.txt`, etc.);
- la identificación de frameworks de pruebas y de la configuración de CI/CD;
- la generación de secciones adecuadas con contenido relevante;
- la aplicación de buenas prácticas para archivos README.

## Instrucciones

Al generar un README, sigue estos pasos.

### 1. Descubrimiento del proyecto

Primero analiza la estructura del proyecto:

- Usa búsquedas de archivos para encontrar archivos clave: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, entre otros.
- Identifica los directorios principales del código fuente.
- Examina los archivos de configuración.
- Busca archivos de pruebas y configuración de CI.

Si existe un `README.md`, revísalo antes de escribir y evita sobrescribir información válida sin considerar una combinación o una mejora incremental.

### 2. Análisis del contenido

Según los hallazgos, determina:

- tipo de proyecto: biblioteca, aplicación, herramienta CLI u otro;
- lenguajes de programación principales;
- dependencias y frameworks;
- comandos de compilación y pruebas;
- tipo de licencia, a partir del archivo `LICENSE` cuando exista.

No inventes comandos, versiones, funcionalidades ni requisitos que no estén respaldados por el proyecto. Si falta información esencial, marca un `TODO` o pregunta al usuario según corresponda.

### 3. Generación del README

Crea un `README.md` con estas secciones y adáptalas al tipo de proyecto.

#### Secciones requeridas

- **Título y descripción:** nombre del proyecto y resumen de una línea.
- **Características:** funcionalidades principales, cuando corresponda.
- **Instalación:** cómo instalar o configurar el proyecto.
- **Uso:** ejemplos básicos de uso.
- **Licencia:** información sobre la licencia, si existe un archivo de licencia.

#### Secciones opcionales

Inclúyelas solo cuando sean relevantes:

- **Requisitos previos:** software y herramientas necesarias.
- **Desarrollo:** cómo preparar el entorno de desarrollo.
- **Pruebas:** cómo ejecutar las pruebas.
- **Contribución:** solo si existen instrucciones o pautas específicas.
- **Documentación de la API:** para bibliotecas y servicios con API.
- **Capturas de pantalla:** para aplicaciones con interfaz de usuario, si hay imágenes disponibles.
- **Hoja de ruta:** planes futuros documentados en el proyecto.
- **Reconocimientos:** créditos y agradecimientos existentes.

### 4. Estilo de redacción

Usa este estilo para los README generados:

- lenguaje claro y conciso;
- voz activa;
- bloques de código con resaltado de sintaxis correcto;
- badges de estado cuando se detecte CI/CD o información equivalente;
- emojis con moderación, únicamente si el usuario los solicita o si ya forman parte de la identidad del proyecto;
- tono profesional, pero cercano.

### 5. Entrega

Presenta el README generado al usuario y ofrece:

- escribirlo en `README.md`;
- hacer ajustes a partir de sus comentarios;
- añadir secciones adicionales.

Si el usuario pidió crear o actualizar el archivo directamente, aplica el cambio siguiendo las reglas de edición del entorno y resume el resultado.

## Ejemplos

### Ejemplo 1: proyecto de Python

**Solicitud del usuario:** «Genera un README para este proyecto de Python».

**Flujo:**

1. Buscar archivos Python: `**/*.py`.
2. Leer `pyproject.toml` o `setup.py`.
3. Revisar `requirements.txt` y `Pipfile` cuando existan.
4. Buscar pruebas en `tests/` o archivos `*_test.py`.
5. Generar el README con:
   - instalación mediante `pip`;
   - requisitos de versión de Python;
   - configuración del entorno virtual;
   - ejecución de pruebas con `pytest` o `unittest`.

### Ejemplo 2: proyecto de Node.js

**Solicitud del usuario:** «Crea un README para mi paquete npm».

**Flujo:**

1. Leer `package.json` para obtener el nombre, la descripción y los scripts.
2. Identificar el framework: React, Vue, Express u otro.
3. Comprobar si existe TypeScript mediante `tsconfig.json`.
4. Buscar la configuración de pruebas: Jest, Mocha u otra.
5. Generar el README con:
   - instalación mediante `npm` o `yarn`;
   - scripts disponibles;
   - documentación de la API, si es un paquete;
   - ejemplos de uso.

## Configuración

La skill se adapta al tipo de proyecto:

| Tipo de proyecto | Archivos clave | Áreas principales |
| --- | --- | --- |
| Python | `pyproject.toml`, `setup.py` | instalación con `pip`, entorno virtual |
| Node.js | `package.json` | instalación con `npm`, scripts |
| Rust | `Cargo.toml` | `cargo build`, funcionalidades |
| Go | `go.mod` | `go get`, módulos |
| Genérico | ninguno | estructura básica |

## Requisitos de herramientas

- **Lectura:** examinar archivos de configuración y código fuente.
- **Búsqueda de archivos:** encontrar archivos relevantes en el proyecto.
- **Búsqueda de texto:** localizar patrones de pruebas, CI/CD y configuración.
- **Edición:** crear el archivo `README.md`.

## Limitaciones

- No puede incluir capturas de pantalla que no existan; el usuario debe añadirlas manualmente.
- Puede no detectar procesos de compilación personalizados que no estén descritos en archivos estándar.
- Genera un punto de partida que el usuario debe revisar y personalizar.
- Funciona mejor con estructuras de proyecto convencionales.
- No analiza en profundidad la lógica del código para determinar todas sus funcionalidades.

## Buenas prácticas

Al usar esta skill:

1. **Ejecuta desde la raíz del proyecto:** asegúrate de estar en el directorio principal.
2. **Revisa antes de escribir:** comprueba el contenido generado antes de guardarlo.
3. **Personaliza:** trata el resultado como una plantilla y añade detalles específicos del proyecto.
4. **Actualiza regularmente:** vuelve a generarlo cuando la estructura del proyecto cambie de forma significativa.
5. **Protege el README existente:** antes de sobrescribirlo, conserva una copia o propone combinar los cambios cuando corresponda.

## Manejo de errores

- **No se encuentran archivos del proyecto:** pide al usuario que confirme el directorio de trabajo.
- **Se detectan varios lenguajes:** genera secciones para cada uno y explica que el proyecto es políglota.
- **Ya existe un README:** informa antes de sobrescribirlo y ofrece combinarlo o actualizarlo.
- **Falta información clave:** genera secciones con marcadores `TODO` o pregunta al usuario por la información necesaria.

## Skills relacionadas

- `changelog-generator`: crear `CHANGELOG.md`.
- `api-doc-generator`: generar documentación de API.
- `license-picker`: añadir archivos de licencia.

## Fuente

Esta skill es una traducción adaptada al formato de Codex de [README Generator](https://github.com/glincker/claude-code-marketplace/blob/main/skills/documentation/readme-generator/SKILL.md), del repositorio `claude-code-marketplace` de GLINCKER.
