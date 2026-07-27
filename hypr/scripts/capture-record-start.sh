#!/usr/bin/env bash
#
# Inicia uma gravação de tela com wf-recorder. Usa "exec" pra SUBSTITUIR o
# processo do bash pelo wf-recorder (mesmo PID) - assim, quando o quickshell
# pede pra parar a gravação (Process.running = false, que manda SIGTERM), o
# sinal chega direto no wf-recorder e ele consegue finalizar o arquivo de
# vídeo corretamente. Sem o "exec", o SIGTERM mataria só o bash e o
# wf-recorder continuaria rodando órfão, sem nunca fechar o arquivo direito.
#
# Usage: capture-record-start.sh <output_file> <geometry|"">

set -euo pipefail

file="${1:?Uso: $(basename "$0") <output_file> <geometry>}"
geometry="${2:-}"

mkdir -p "$(dirname "$file")"

if [ -n "$geometry" ]; then
    exec wf-recorder -g "$geometry" -f "$file"
else
    exec wf-recorder -f "$file"
fi
