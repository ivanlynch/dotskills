#!/usr/bin/env bash
set -euo pipefail

die() { echo "Error: $*" >&2; exit 2; }
id=''; tipo=''; descripcion=''; archivo=''; redactado=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --investigacion) id=${2:-}; shift 2;;
    --tipo) tipo=${2:-}; shift 2;;
    --descripcion) descripcion=${2:-}; shift 2;;
    --archivo) archivo=${2:-}; shift 2;;
    --redactado) redactado=1; shift;;
    *) die "opción desconocida: $1";;
  esac
done
[[ -n "$id" && -n "$tipo" && -n "$descripcion" && -n "$archivo" ]] || die "faltan argumentos"
[[ "$tipo" == evidencia || "$tipo" == reproduccion || "$tipo" == experimento || "$tipo" == resultado ]] || die "tipo inválido"
[[ -f "$archivo" ]] || die "no existe el archivo: $archivo"
[[ $redactado -eq 1 ]] || die "solo se aceptan archivos marcados como redactados"
root=${INVESTIGACIONES_ROOT:-"$HOME/Documents/research"}
target="$root/$id"
[[ -f "$target/metadata/manifest.tsv" ]] || die "investigación inexistente o incompleta"
case "$tipo" in
  evidencia) dir=evidencia; prefix=E;;
  reproduccion) dir=reproduccion; prefix=R;;
  experimento) dir=experimentos; prefix=X;;
  resultado) dir=resultados; prefix=O;;
esac
count=$(awk -F '\t' -v p="$prefix-" 'NR>1 && index($1,p)==1 {n++} END {print n+0}' "$target/metadata/manifest.tsv")
num=$(printf '%03d' $((count + 1)))
artifact_id="$prefix-$num"
base=$(basename "$archivo")
safe=${base//[^A-Za-z0-9._-]/_}
dest="$target/$dir/$artifact_id-$safe"
cp -- "$archivo" "$dest"
if command -v shasum >/dev/null 2>&1; then sha=$(shasum -a 256 "$dest" | awk '{print $1}'); else sha=$(sha256sum "$dest" | awk '{print $1}'); fi
now=$(date '+%Y-%m-%dT%H:%M:%S%z')
clean_desc=${descripcion//$'\t'/ }
line="$artifact_id\t$tipo\t$clean_desc\t${dest#"$target/"}\t$sha\t$now\tREGISTRADO"
printf '%s\n' "$line" >> "$target/metadata/manifest.tsv"
printf '%s\t%s\n' "$artifact_id" "${dest#"$target/"}"
