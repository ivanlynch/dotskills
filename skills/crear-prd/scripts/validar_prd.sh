#!/usr/bin/env bash
# Chequea que un PRD tenga las secciones obligatorias de la plantilla.
# Uso: validar_prd.sh <ruta-al-prd.md>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: $0 <ruta-al-prd.md>" >&2
  exit 2
fi

prd="$1"

if [ ! -f "$prd" ]; then
  echo "ERROR: no existe el archivo: $prd" >&2
  exit 1
fi

secciones=(
  "## Por qué"
  "## Evidencia"
  "## Supuestos"
  "## Alcance"
  "## Requisitos"
  "## Requisitos no funcionales"
  "## Riesgos abiertos"
  "## Changelog"
)

faltantes=0
for s in "${secciones[@]}"; do
  if grep -qF "$s" "$prd"; then
    echo "PASS  $s"
  else
    echo "FAIL  $s (falta)"
    faltantes=$((faltantes + 1))
  fi
done

echo "---"
if [ "$faltantes" -eq 0 ]; then
  echo "VEREDICTO: ESTRUCTURA COMPLETA"
  exit 0
else
  echo "VEREDICTO: FALTAN $faltantes SECCIONES"
  exit 1
fi
