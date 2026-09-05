# 0001. Id incremental con prefijo para investigaciones

## Estado

Aceptada

## Contexto

Cada investigación de `diagnosticar-bugs` se identifica con un `<id>` que hasta
ahora era un slug elegido a mano por la IA a partir de lo que describe el
usuario (ej. `export-timeout-500`), pasado a `estado.sh init <id>`. Ese `<id>`
determina la ruta `$DIAGNOSTICOS_ROOT/<slug-proyecto>/<id>/`.

El script en sí (`estado.sh init`) es mecánico e idempotente: si la carpeta ya
existe, no la toca, solo imprime la ruta. Pero el `<id>` que recibe como
input no lo es — lo elige la IA, y el script solo valida su formato
(`[a-z0-9][a-z0-9-]{2,62}[a-z0-9]`), no su unicidad semántica. Si dos
investigaciones distintas en el mismo repo terminan con el mismo `<id>`
(por descuido, por convención o por coincidencia), la segunda `init` hereda
en silencio la carpeta de la primera en vez de fallar o avisar.

Este problema se investigó en el spike
[#6](https://github.com/ivanlynch/dotskills/issues/6), que comparó tres
opciones: id predefinido/generado, id basado en lo que escribe el usuario
(esquema anterior), e híbridos.

## Decisión

Reemplazar el slug elegido por la IA por un **id autogenerado, incremental y
numérico, con el prefijo `INV`**, con ancho de al menos 3 dígitos con ceros a
la izquierda: `INV001`, `INV002`, `INV003`, ..., `INV010`, ..., `INV100`.

- El número lo asigna el script (no la IA ni el usuario), leyendo y
  actualizando un contador persistente por proyecto (scope: mismo
  `<slug-proyecto>` que ya aísla repos distintos).
- El incremento debe ser atómico (lock a nivel de archivo) para evitar
  colisiones si dos diagnósticos arrancan casi al mismo tiempo.
- Se descarta la variante híbrida (número + slug del usuario, ej.
  `INV003-export-timeout-500`): se prioriza que el id sea 100% mecánico y
  determinista en su generación, sin ningún componente elegido por la IA.
  La legibilidad humana se resuelve en la cabecera de `DIAGNOSTICO.md`
  (proyecto, branch, commit), no en el nombre de la carpeta — mismo
  criterio ya aplicado al `<slug-proyecto>`.

## Consecuencias

- Elimina la dependencia del juicio de la IA para no colisionar con una
  investigación abierta: la Fase 0 pasa a ser mecánica de punta a punta,
  incluyendo la elección del id.
- Se pierde la propiedad actual de que la ruta es determinista solo a
  partir de `(repo, id)` provisto externamente: ahora depende de estado
  mutable compartido (el contador), que necesita manejo de concurrencia.
- Requiere un mecanismo para descubrir investigaciones abiertas (ej.
  `estado.sh listar`), ya que el id numérico no es memorable ni describe el
  bug — hoy no existe ese comando.
- Cambia la interfaz de `estado.sh init`: deja de aceptar un `<id>` como
  argumento y pasa a devolver el id que generó.
