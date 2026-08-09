# Checklist de validación de skills

Lista estática de puntos que audita `/validar-skill`. No es un artefacto por
corrida — vive acá como definición. El estado por corrida (qué está `DONE`,
`NA` o `PENDING` para un skill puntual) lo guarda `scripts/validar_skill.sh`
en un archivo temporal fuera del repo.

Los puntos marcados «(condicional)» solo aplican si el campo o directorio
correspondiente existe en el skill evaluado; si no existe, se marcan `NA`.
El resto son obligatorios siempre.

`scripts/validar_skill.sh` extrae los IDs de la primera columna de esta
tabla — no cambies el formato de las filas sin actualizar el script.

| ID | Descripción |
| --- | --- |
| `dir-nombre-coincide` | El nombre del directorio (`skills/<nombre>/`) coincide exactamente con `name` en el frontmatter. |
| `name-longitud` | `name` tiene entre 1 y 64 caracteres. |
| `name-charset` | `name` solo contiene minúsculas unicode alfanuméricas y guiones. |
| `name-sin-guion-borde` | `name` no empieza ni termina con guion. |
| `name-sin-guion-doble` | `name` no tiene guiones consecutivos (`--`). |
| `description-longitud` | `description` tiene entre 1 y 1024 caracteres, no vacía. |
| `description-que-y-cuando` | `description` describe qué hace el skill **y** cuándo usarlo. |
| `description-palabras-clave` | `description` incluye palabras clave específicas que ayudan a decidir cuándo activarlo. |
| `license-formato` (condicional) | Si existe `license`: nombre corto de licencia o referencia a un archivo de licencia incluido. |
| `compatibility-formato` (condicional) | Si existe `compatibility`: 1 a 500 caracteres. |
| `compatibility-necesidad-real` (condicional) | Si existe `compatibility`: el skill tiene un requisito de entorno real, no se agregó preventivamente. |
| `metadata-formato` (condicional) | Si existe `metadata`: es un mapa string→string. |
| `metadata-claves-unicas` (condicional) | Si existe `metadata`: sus claves son razonablemente únicas, sin choque previsible con otras herramientas. |
| `allowed-tools-formato` (condicional) | Si existe `allowed-tools`: string separado por espacios. |
| `cuerpo-idioma-espanol` | El cuerpo (fuera de bloques de código) está en español. |
| `cuerpo-instrucciones-accionables` | El cuerpo da pasos concretos, no solo generalidades. |
| `cuerpo-longitud` | El `SKILL.md` completo tiene menos de 500 líneas. |
| `referencias-rutas-relativas` | Toda referencia a otro archivo del skill usa ruta relativa desde la raíz del skill, sin subir niveles (`../`). |
| `referencias-un-nivel` | Las referencias no encadenan más de un nivel de profundidad (una referencia no apunta a otra referencia). |
| `scripts-documentados` (condicional) | Si existe `scripts/`: cada script documenta sus dependencias y maneja errores con mensajes claros. |
| `scripts-bash-no-python` (condicional) | Si existe `scripts/`: los scripts son bash (`.sh`), no Python ni otro runtime que requiera instalar un intérprete aparte. |
| `scripts-no-duplicados` | Ningún script bundleado duplica uno que ya es propiedad de otro skill del repo (debería referenciarlo por nombre de skill vecino en vez de copiarlo). |
| `ubicacion-exclusiva` | El skill vive únicamente en `skills/<nombre>/` — no hay copias en otras carpetas del repo. |
| `prefijo-referencias-slash` | Las referencias a otros skills dentro del cuerpo usan `/nombre`, no `$nombre` ni otro prefijo. |
