---
name: commit
description: Analiza cambios staged o commits existentes, propone mensajes en inglés siguiendo Conventional Commits y crea o reescribe commits después de la confirmación del usuario. Usar cuando el usuario invoque $commit o pida generar, renombrar, reorganizar o reescribir commits.
---

# Commit

Gestionar commits nuevos o existentes siguiendo Conventional Commits. La operación puede partir de cambios staged o de un rango de commits indicado por el usuario; no exigir staging cuando el objetivo sea reescribir el historial.

## Elegir el modo de trabajo

- **Commit nuevo:** usar los cambios staged como fuente principal. Si el usuario pidió explícitamente crear el commit y el alcance es identificable, stagear únicamente los archivos correspondientes antes de analizarlos. No incorporar cambios ajenos, ambiguos o untracked sin relación con el pedido.
- **Reescritura de commits:** usar únicamente los commits y sus diffs dentro del rango solicitado. No agregar archivos nuevos ni incluir cambios unstaged o untracked.
- **Rebase o reorganización:** identificar primero la branch base, el rango exacto y el orden resultante. No modificar el historial hasta que el usuario confirme los mensajes y la operación.

## 1. Validar el alcance

Para un commit nuevo, revisar primero `git status --short`. Si no hay cambios staged pero el usuario pidió explícitamente crear el commit:

- Identificar los archivos que pertenecen al cambio solicitado usando el contexto de la tarea y `git diff -- <rutas>`.
- Ejecutar `git add -- <rutas exactas>` solamente para esos archivos.
- Si el alcance no puede distinguirse con seguridad de otros cambios locales, detenerse y pedir al usuario que indique qué rutas incluir.

Después, ejecutar en paralelo:

```bash
git status --short
git diff --staged
git diff --staged --stat
```

Si todavía no hay archivos staged, detenerse e informar brevemente que no hay cambios dentro del alcance para commitear.

Para reescribir commits existentes, ejecutar:

```bash
git status --short
git log --oneline <base>..HEAD
git diff <base>..HEAD
```

Si existen cambios unstaged o untracked, mostrar únicamente sus rutas y preguntar en portugués si deben quedar fuera o si el usuario quiere incorporarlos. Nunca incorporarlos silenciosamente a la reescritura.

Antes de un rebase, confirmar que el rango no incluya commits fuera del alcance solicitado. Si la branch ya fue publicada, informar que será necesario `git push --force-with-lease` después de la reescritura.

## 2. Analisar e redigir

Usar como fuente el staging en el modo de commit nuevo, o los diffs de los commits seleccionados en el modo de reescritura. Consultar el historial reciente únicamente para alinhar o estilo dos mensajes, no para inventar contenido.

Redactar cada mensaje en inglés con estas reglas:

| Campo | Regra |
|---|---|
| `type` | Uno de `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`. Elegir según la intención del cambio. |
| `scope` | Opcional. Usar el módulo o área afectada solo si es claro; no inventarlo. Mantener kebab-case o camelCase consistente con el repositorio. |
| `subject` | Imperativo, presente, máximo 72 caracteres, sin punto final. Describir qué cambia para el usuario o sistema. |
| `body` | Opcional, una sola línea en inglés con contexto, motivo o efecto colateral. Omitir si el subject es autoexplicativo. |

Añadir el ticket Jira al body únicamente si aparece explícitamente en el diff, la branch o la petición del usuario.

## 3. Mostrar y confirmar

Responder en portugués, brevemente, incluyendo para cada commit:

### Campos (referência)

Listar `type`, `scope` —usando `—` si se omite—, `subject` y `body` —usando `—` si se omite—.

### Mensagem para copiar

Para un commit nuevo, mostrar un único bloque con el comando listo para ejecutar:

```bash
git commit -m "type(scope): subject" -m "body single line"
```

Para una reescritura, mostrar la tabla de commits actuales y los mensajes propuestos, además del comando de rebase que se ejecutará. Si la branch ya fue publicada, incluir explícitamente:

```bash
git push --force-with-lease origin <branch>
```

No ejecutar `git commit`, `git rebase` ni `git push --force-with-lease` sin confirmación explícita del usuario.

## 4. Ejecutar

Con confirmación afirmativa:

- **Commit nuevo:** ejecutar directamente `git commit` con el mensaje aprobado.
- **Renombrar commits:** ejecutar un rebase interactivo o equivalente sobre el rango aprobado, conservando el contenido y cambiando únicamente los mensajes solicitados.
- **Reorganizar commits:** usar el rebase aprobado y verificar que cada commit resultante conserve el alcance esperado.
- **Branch publicada:** ejecutar `git push --force-with-lease`, nunca `git push --force`.

Después de ejecutar, verificar:

```bash
git status --short
git log --oneline <base>..HEAD
```

Informar el resultado en portugués, incluyendo los hashes nuevos cuando el historial haya sido reescrito. Si una operación falla o aparece un conflicto, detenerse y describir el estado sin resolverlo destructivamente.
