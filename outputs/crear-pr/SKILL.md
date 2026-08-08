---
name: crear-pr
description: Prepara y abre pull requests a partir de un ticket de Jira y cambios ya implementados. Úsala para generar la descripción, respetar las instrucciones o plantilla del repositorio y abrir una PR con el título obligatorio `[<JIRA TICKET>] <Título del ticket de Jira>`.
---

# Crear PR

Prepara y abre una pull request concisa, verificable y alineada con el repositorio. Esta skill recibe como contexto el ID y el título del ticket de Jira, la branch actual, los cambios implementados y sus verificaciones.

## Regla obligatoria del título

El título de la PR debe tener exactamente este formato:

```text
[<JIRA TICKET>] <Título del ticket de Jira>
```

Ejemplo:

```text
[PROJ-1234] Arreglar tal cosa
```

Reglas:

- Usa el ID de Jira normalizado en mayúsculas.
- Usa el título leído desde Jira, no una paráfrasis ni el nombre de la branch.
- Conserva el contenido del título de Jira salvo espacios innecesarios al inicio o al final.
- No agregues prefijos adicionales como `feat:`, `fix:` o el nombre del proyecto.
- No abras la PR si falta el ID o el título verificado del ticket; bloquea el flujo y solicita el dato faltante.

## Flujo

### 1. Verificar el contexto

Antes de preparar la PR, confirma:

- ID del ticket de Jira;
- título exacto del ticket leído desde Jira;
- branch actual y branch de destino;
- cambios incluidos en los commits;
- verificaciones ejecutadas y su resultado;
- aprobación previa del alcance, cuando la skill que te invoca la requiera.

No inventes datos ni presentes como ejecutadas verificaciones que no tengan evidencia.

### 2. Buscar las reglas del repositorio

Busca primero, desde la raíz del proyecto:

1. comandos, skills o instrucciones locales para crear o abrir PRs;
2. `AGENTS.md`, `AGENTS.override.md`, `.codex/`, `.agents/` y documentación de contribución relevante;
3. plantillas llamadas `pull_request_template.md`, sin distinguir mayúsculas/minúsculas, incluyendo `.github/` y sus subdirectorios.

Si existe un flujo local aplicable, obedécelo. Si existe una plantilla, conserva todas sus secciones y el mismo orden. No elimines secciones; usa `No aplica` con una explicación breve cuando una sección no corresponda.

### 3. Preparar la descripción

Si no hay una plantilla aplicable, usa una estructura breve:

```markdown
## Resumen

[Qué se cambió y por qué, en uno o dos enunciados]

## Cambios

- [Cambio relevante]
- [Cambio relevante]

## Verificaciones

- [Comando o verificación]: PASS/FAIL — [resultado breve]
```

Adapta la descripción a las reglas locales. Mantén las secciones objetivas, evita contexto redundante y no pegues logs completos ni diffs extensos.

### 4. Validar antes de publicar

Comprueba antes de abrir la PR:

- el título cumple literalmente `[ID] Título de Jira`;
- el ID del título coincide con el ticket trabajado;
- la branch contiene únicamente cambios del alcance aprobado;
- la branch está subida o puede subirse al remoto previsto;
- las verificaciones están reflejadas con resultados reales;
- no se exponen secretos, tokens o credenciales;
- la descripción cumple la plantilla o instrucciones locales.

Si falla una comprobación, no abras la PR. Explica el bloqueo y el siguiente paso exacto.

### 5. Publicar y confirmar

Sube la branch y abre la PR mediante el flujo disponible del proyecto. Tras la operación, confirma que la PR existe y que su título quedó con el formato obligatorio. Informa únicamente:

- enlace de la PR;
- título final;
- verificaciones realizadas;
- deuda técnica real generada o pendiente.

Marca la tarea como completada solo después de confirmar la URL de la PR.

## Integración con `$cocinar`

Cuando `$cocinar` llegue a su fase `pr`, debe invocar esta skill con el ID y el título verificado de Jira, la branch, los commits y las verificaciones. `$cocinar` conserva el control de la máquina de estados; esta skill concentra la preparación, validación y apertura de la PR.
