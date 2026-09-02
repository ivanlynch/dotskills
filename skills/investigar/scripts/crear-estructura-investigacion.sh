#!/usr/bin/env bash
set -euo pipefail

usage() { echo "Uso: $0 <identificador>" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
id=$1
[[ "$id" =~ ^[a-z0-9][a-z0-9-]{2,62}[a-z0-9]$ ]] || { echo "Identificador inválido: usa minúsculas, números y guiones." >&2; exit 2; }
skill_dir=$(cd "$(dirname "$0")/.." && pwd)
root=${INVESTIGACIONES_ROOT:-"$HOME/Documents/research"}
target="$root/$id"
[[ ! -e "$target" ]] || { echo "La investigación ya existe: $target" >&2; exit 1; }
mkdir -p "$target"/{evidencia,reproduccion,experimentos,resultados,metadata}
template="$skill_dir/assets/templates/investigacion.md"
[[ -f "$template" ]] || { echo "No existe el template: $template" >&2; exit 1; }
now=$(date '+%Y-%m-%dT%H:%M:%S%z')
sed -e "s/{{identificador}}/$id/g" -e "s/{{fecha_inicio}}/$now/g" -e "s/{{fecha_actualizacion}}/$now/g" "$template" > "$target/investigacion.md"
printf 'id\ttipo\tdescripcion\truta\tsha256\tfecha\testado\n' > "$target/metadata/manifest.tsv"
: > "$target/metadata/respuestas.log"
: > "$target/metadata/comandos.ndjson"
printf 'investigacion_id=%s\nfecha_inicio=%s\nraiz=%s\n' "$id" "$now" "$target" > "$target/metadata/entorno.txt"
printf '%s\n' "$target"
