#!/usr/bin/env bash
# Dependencies: bash, rg and standard POSIX utilities (mktemp, cat, mv).
# Exit code 6 indicates invalid or incomplete input.
set -euo pipefail
usage() { echo "Uso: $0 --context-file F --problem-file F --objective-file F --scope-file F --acceptance-file F --out-of-scope-file F --resources-file F --output-file F" >&2; exit 6; }
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
template_file="$(cd -- "$script_dir/.." && pwd)/templates/technical-task.md"
context_file=""; problem_file=""; objective_file=""; scope_file=""; acceptance_file=""; out_of_scope_file=""; resources_file=""; output_file=""
while [[ $# -gt 0 ]]; do case "$1" in
--template-file) template_file="$2"; shift 2 ;;
--context-file) context_file="$2"; shift 2 ;;
--problem-file) problem_file="$2"; shift 2 ;;
--objective-file) objective_file="$2"; shift 2 ;;
--scope-file) scope_file="$2"; shift 2 ;;
--acceptance-file) acceptance_file="$2"; shift 2 ;;
--out-of-scope-file) out_of_scope_file="$2"; shift 2 ;;
--resources-file) resources_file="$2"; shift 2 ;;
--output-file) output_file="$2"; shift 2 ;;
-h|--help) usage ;;
*) echo "Argumento desconhecido: $1" >&2; usage ;;
esac; done
[[ -f "$template_file" && -n "$output_file" ]] || usage
files=("$context_file" "$problem_file" "$objective_file" "$scope_file" "$acceptance_file" "$out_of_scope_file" "$resources_file")
for file in "${files[@]}"; do [[ -s "$file" ]] || { echo "Arquivo de seção vazio ou inexistente: $file" >&2; exit 6; }; done
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
while IFS= read -r line || [[ -n "$line" ]]; do case "$line" in
'<!-- CONTEXTO -->') cat "$context_file" ;;
'<!-- PROBLEMA -->') cat "$problem_file" ;;
'<!-- OBJETIVO -->') cat "$objective_file" ;;
'<!-- ESCOPO -->') cat "$scope_file" ;;
'<!-- CRITERIOS_DE_ACEITE -->') cat "$acceptance_file" ;;
'<!-- FORA_DE_ESCOPO -->') cat "$out_of_scope_file" ;;
'<!-- RECURSOS -->') cat "$resources_file" ;;
*) printf '%s\n' "$line" ;;
esac; done < "$template_file" > "$tmp"
expected=("## Contexto" "## Problema" "## Objetivo" "## Escopo" "## Critérios de aceite" "## Fora de escopo" "## Recursos"); previous=0
for heading in "${expected[@]}"; do current="$(rg -n -m 1 -F "$heading" "$tmp" | cut -d: -f1)"; [[ -n "$current" && "$current" -gt "$previous" ]] || { echo "Estrutura inválida" >&2; exit 6; }; previous="$current"; done
mv "$tmp" "$output_file"
