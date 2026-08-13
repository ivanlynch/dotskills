#!/usr/bin/env bash
set -euo pipefail

die() { echo "Error: $*" >&2; exit 2; }
id=''; seccion=''; desde_stdin=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --investigacion) id=${2:-}; shift 2;;
    --seccion) seccion=${2:-}; shift 2;;
    --texto-stdin) desde_stdin=1; shift;;
    *) die "opción desconocida: $1";;
  esac
done
[[ -n "$id" && -n "$seccion" && $desde_stdin -eq 1 ]] || die "usa --investigacion, --seccion y --texto-stdin"
case "$seccion" in
  sintoma) placeholder=sintoma;;
  contexto) placeholder=contexto;;
  reproduccion) placeholder=reproduccion;;
  deltas) placeholder=deltas;;
  fuentes_evidencia) placeholder=fuentes_evidencia;;
  diagnostico_inicial) placeholder=diagnostico_inicial;;
  hipotesis) placeholder=hipotesis;;
  experimentos) placeholder=experimentos;;
  analisis_impacto) placeholder=analisis_impacto;;
  conclusion_final) placeholder=conclusion_final;;
  registro_decisiones) placeholder=registro_decisiones;;
  *) die "sección inválida: $seccion";;
esac
root=${INVESTIGACIONES_ROOT:-"$HOME/Documents/research"}
target="$root/$id"
report="$target/investigacion.md"
[[ -f "$report" && -f "$target/metadata/respuestas.log" ]] || die "investigación inexistente o incompleta"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"
[[ -s "$tmp" ]] || die "la respuesta está vacía"
marker="{{$placeholder}}"
grep -Fqx "$marker" "$report" || die "placeholder ausente o ya completado: $marker"
awk -v marker="$marker" -v input="$tmp" '
  $0 == marker {
    while ((getline line < input) > 0) print line
    found=1
    next
  }
  { print }
  END { if (!found) exit 1 }
' "$report" > "$report.tmp"
mv "$report.tmp" "$report"
now=$(date '+%Y-%m-%dT%H:%M:%S%z')
printf '%s\t%s\t%s\n' "$now" "$seccion" "$(tr '\n' ' ' < "$tmp")" >> "$target/metadata/respuestas.log"
printf '%s\n' "$seccion"
