---
name: revisar-codigo
description: Revisa manualmente una pull request de GitHub mediante dos ejes independientes, Estándares y Especificación, y confirma cada defecto con evidencia reproducible contra referencias Git fijadas. Usar solo cuando el usuario invoque explícitamente revisar-codigo con un número de PR.
compatibility: Requiere un checkout Git, Bash, jq, GitHub CLI autenticada y acceso de lectura al repositorio remoto; Jira es opcional mediante /consultar-ticket.
---

# Revisar Código

Revisa una pull request sin modificar su implementación ni publicar acciones en
GitHub. Separa siempre dos ejes:

- **Estándares:** cumplimiento de instrucciones y convenciones del repositorio.
- **Especificación:** cumplimiento de los requisitos del ticket o documento de
  origen.

Los subagentes proponen candidatos. Solo el agente principal puede convertir un
candidato en hallazgo después de reproducirlo y demostrar su causa e impacto.

## Reglas no negociables

- Ejecutar esta skill únicamente por invocación explícita del usuario.
- Recibir un número de PR. Si falta, pedirlo; no asumir una PR, rama o referencia.
- No cambiar el checkout actual, los archivos versionados ni la PR.
- No publicar comentarios, aprobaciones ni solicitudes de cambios en GitHub.
- No crear un informe dentro del repositorio. Entregarlo en la conversación.
- No presentar posibilidades, riesgos hipotéticos ni sospechas como hallazgos.
- No asignar severidad ni emitir un veredicto global de aprobación o rechazo.
- Adaptar el informe al idioma de la última instrucción del usuario. Si no es
  claro, usar el idioma predominante de la conversación. Conservar citas,
  identificadores y salidas técnicas en su idioma original.

## 1. Fijar el contexto de la PR

Ejecutar:

```bash
<skill-dir>/scripts/preparar_revision.sh <numero-pr>
```

El script consulta la PR, fija los SHA de base y cabeza, obtiene el merge-base,
calcula el tamaño del diff, enumera los commits y extrae posibles IDs de Jira de
la rama origen. Usar el `merge_base` devuelto como punto fijo para el diff y para
la comparación del comportamiento anterior.

Detenerse en cualquiera de estos casos:

- La referencia no existe o no puede descargarse: mostrar el error concreto.
- El diff está vacío: informar que no hay cambios que revisar.
- El diff supera 50 archivos o 3000 líneas agregadas/eliminadas: mostrar ambas
  métricas y pedir autorización para revisarlo completo, o proponer dividirlo
  por componentes o rangos de commits. No muestrear silenciosamente.
- No aparece un ID Jira o aparecen varios: pedir al usuario el ID correcto. No
  elegirlo por inferencia.

Registrar para el informe: número y URL de PR, estado, ramas, SHA de base y
cabeza, merge-base, ticket y lista de commits. Aunque las ramas se muevan durante
la revisión, continuar con esos SHA y aclarar que commits posteriores no están
incluidos.

## 2. Obtener la especificación

Aplicar esta prioridad:

1. Fuente indicada explícitamente por el usuario.
2. Ticket Jira extraído y confirmado desde la rama origen.
3. Archivo local inequívoco bajo `docs/`, `specs/` o un directorio equivalente.

Para Jira, invocar `/consultar-ticket <ID>` y usar su título y descripción sin
completarlos ni reinterpretar datos ausentes. No consultar subtareas o tickets
enlazados salvo que el ticket los declare parte de sus requisitos o el usuario
lo solicite.

La descripción de la PR y los commits son contexto de implementación, no fuente
de requisitos. Si dos fuentes de especificación se contradicen, pausar este eje
y pedir al usuario que elija la fuente de verdad.

Si una referencia de Jira no es accesible, avisar de inmediato y pedir al
usuario que proporcione el contenido o autorice explícitamente omitir el eje
Especificación. Se puede avanzar con verificaciones independientes de
Estándares, pero no cerrar la revisión mientras la decisión esté pendiente.

Si el usuario confirma que no existe especificación, omitir el subagente de ese
eje y registrar: «Especificación no disponible; eje omitido» en el idioma del
informe.

## 3. Reunir los estándares aplicables

Inspeccionar instrucciones generales y las que estén más cerca de cada archivo
modificado: `AGENTS.md`, `CLAUDE.md`, reglas de Cursor, `CONTRIBUTING.md`,
documentos de estándares, README y equivalentes.

Resolver contradicciones con esta prioridad:

1. Instrucción explícita del usuario.
2. Instrucción aplicable más cercana al archivo dentro del árbol de directorios.
3. Regla general del repositorio.
4. Catálogo base de `references/catalogo-code-smells.md`.

Leer el catálogo completo antes de lanzar el eje Estándares. Sus elementos son
heurísticas de diseño, nunca infracciones automáticas. Una regla documentada del
repositorio siempre prevalece. Si un linter, type checker u otra herramienta
garantiza una regla y pasa correctamente, no duplicar ese control manualmente.

## 4. Crear entornos aislados

Crear un directorio temporal y dos worktrees detached: uno en `merge_base` y
otro en `head_sha`. No ejecutar comparaciones en el checkout del usuario, aunque
esté limpio.

```bash
git worktree add --detach <directorio-temporal>/base <merge_base>
git worktree add --detach <directorio-temporal>/head <head_sha>
```

Descubrir los comandos de validación en este orden:

1. Instrucciones del repositorio.
2. Scripts declarados en `package.json`, `Makefile` o equivalentes.
3. Comandos ad hoc mínimos para aislar un comportamiento.

Empezar por tests y comandos específicos de los archivos modificados. Después,
ejecutar las validaciones generales que el repositorio declare obligatorias.

Ejecutar automáticamente solo validaciones locales y seguras. Pedir
confirmación antes de usar red, credenciales, servicios externos, contenedores,
migraciones o cualquier acción con efectos fuera de los worktrees temporales.

## 5. Lanzar los dos ejes

Ejecutar en paralelo cuando la plataforma lo permita. Si no permite paralelismo,
ejecutarlos por separado sin compartir conclusiones entre contextos. Ambos
pueden leer el diff completo y el código circundante necesario, pero solo deben
atribuir candidatos al cambio cuando exista una relación concreta con el diff.

### Subagente de Estándares

Entregarle:

- comando exacto `git diff <merge_base>..<head_sha>` y lista de commits;
- archivos de estándares encontrados y su prioridad;
- contenido completo de `references/catalogo-code-smells.md`;
- instrucciones para revisar todo el diff, sin detenerse en el primer problema.

Pedirle dos listas:

- **Candidatos verificables:** comportamientos que parecen fallar por el cambio
  y que pueden comprobarse mediante ejecución.
- **Observaciones estáticas:** incumplimientos documentados o code smells con
  archivo, fragmento y regla exactos, sin afirmar impactos hipotéticos.

No permitir que declare hallazgos confirmados ni severidades.

### Subagente de Especificación

Entregarle:

- el mismo diff y lista de commits;
- la fuente completa de la especificación;
- la instrucción de citar el requisito exacto para cada candidato.

Pedirle que busque requisitos faltantes o parciales, comportamiento incorrecto
y trabajo fuera de alcance. Un requisito faltante o incorrecto es solo un
candidato hasta que se ejecute una reproducción observable. El trabajo fuera de
alcance sin efecto demostrable es una observación, no un defecto.

No permitir que declare hallazgos confirmados ni severidades.

## 6. Verificar cada candidato

El agente principal debe verificar cada candidato de forma independiente. Para
cada comando en cada worktree, usar:

```bash
<skill-dir>/scripts/repetir_comando.sh <worktree> -- <comando> [argumentos...]
```

El script ejecuta dos veces, conserva salidas separadas y muestra si coinciden.
Leer las salidas, distinguir diferencias irrelevantes como timestamps y borrar
el directorio temporal del script después de extraer la evidencia necesaria.

### Condiciones para confirmar un hallazgo

Exigir todas:

1. El mismo comportamiento relevante aparece en dos ejecuciones de `HEAD`.
2. Existe un resultado esperado objetivo, respaldado por la especificación, una
   regla ejecutable o el comportamiento anterior.
3. La causa está demostrada y vinculada a una parte concreta del diff.
4. El impacto es visible, específico y afecta la implementación o un
   comportamiento que funcionaba.
5. Los pasos y comandos permiten que otra persona repita la comprobación.

Para una regresión o fallo de tooling, ejecutar también dos veces en el
merge-base: debe funcionar allí y fallar en `HEAD`. Si falla en ambos, es un
problema preexistente y no se atribuye a la PR.

Para un requisito nuevo, demostrar dos veces en `HEAD` que el comportamiento
observable contradice el requisito. El merge-base sirve como contexto, pero no
se exige que implemente una funcionalidad que todavía no existía.

Si no hay un test existente, se puede crear un script o fixture temporal fuera
del repositorio y ejecutarlo contra ambos worktrees. No editar archivos
versionados para producir evidencia.

Resultados de CI y comentarios existentes solo orientan la búsqueda. No son
hallazgos hasta reproducirlos con este proceso.

### Bloqueos e incertidumbre

Si falta una dependencia, credencial, dato o servicio para ejecutar una
validación, avisar al usuario de inmediato. Explicar qué hace falta y pedir una
decisión explícita: proporcionarlo o ignorar únicamente esa validación. Mientras
espera, continuar con verificaciones independientes, pero no cerrar el informe.

Registrar toda omisión autorizada como limitación. Un error de entorno solo es
hallazgo si se demuestra que `HEAD` lo introdujo y el merge-base no lo presenta.

Si el fallo se reproduce pero su causa no está demostrada, clasificarlo como
**verificación inconclusa**. Si las dos ejecuciones no coinciden, clasificarlo
como comportamiento inestable inconcluso. Nunca completar la causa por
inferencia.

## 7. Clasificar los resultados

Usar estas categorías sin mezclarlas:

- **Hallazgo verificado:** defecto ejecutado dos veces, con causa e impacto
  demostrados.
- **Observación:** condición estática exacta, respaldada por una regla o code
  smell, sin afirmar un fallo ni una consecuencia no comprobada.
- **Verificación inconclusa:** evidencia parcial, bloqueo autorizado o resultado
  inestable que no permite confirmar causa e impacto.

Varias manifestaciones de una misma causa raíz forman un único hallazgo con
todos los casos reproducidos. Revisar todo el diff; no limitar la cantidad de
hallazgos.

Cada hallazgo debe incluir ubicación, condición inicial, comandos o pasos,
resultado esperado, resultados de ambas ejecuciones, comparación con el
merge-base cuando aplique, causa, impacto y dirección de corrección. La
dirección de corrección es una propuesta no implementada ni validada.

Cada observación debe citar archivo y fragmento, regla o code smell aplicable y
la coincidencia concreta. No usar expresiones como «podría romper» o «puede
afectar».

## 8. Entregar y limpiar

Leer y seguir `references/formato-informe.md`. Mantener separados Estándares y
Especificación; no fusionar ni reordenar hallazgos entre ejes.

Si no hay hallazgos, mostrar igualmente el alcance, los comandos ejecutados y
las limitaciones. «Sin hallazgos» significa que no se confirmó ningún problema
dentro del alcance revisado, no que el cambio sea correcto de forma absoluta.

Redactar secretos, tokens, datos personales y valores sensibles de comandos y
salidas. Conservar solo la evidencia mínima necesaria.

Al terminar, eliminar únicamente los worktrees, logs y archivos temporales
creados por esta ejecución. Verificar sus rutas exactas antes de borrarlos. No
eliminar ni restaurar archivos del usuario.
