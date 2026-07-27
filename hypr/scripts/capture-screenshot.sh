#!/usr/bin/env bash
#
# Tira uma screenshot com grim, opcionalmente copiando pro clipboard e/ou
# notificando quando termina. O caminho completo do arquivo já vem pronto
# (quickshell decide o nome/pasta, este script só executa a captura).
#
# Usage: capture-screenshot.sh <output_file> <geometry|""> <copy:0|1> <notify:0|1>

set -euo pipefail

file="${1:?Uso: $(basename "$0") <output_file> <geometry> <copy> <notify>}"
geometry="${2:-}"
copy="${3:-0}"
notify="${4:-0}"

mkdir -p "$(dirname "$file")"

if [ -n "$geometry" ]; then
    grim -g "$geometry" "$file"
else
    grim "$file"
fi

[ "$copy" = "1" ] && wl-copy < "$file"
[ "$notify" = "1" ] && notify-send -i "$file" "Captura de tela" "Salva em $file"

exit 0
