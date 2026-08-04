#!/usr/bin/env bash
#
# Tira uma screenshot com grim, opcionalmente copiando pro clipboard e/ou
# notificando quando termina. O caminho completo do arquivo já vem pronto
# (quickshell decide o nome/pasta, este script só executa a captura).
#
# "source_file" (opcional) é o print de tela cheia "congelado" no instante
# em que o usuário ativou a ferramenta (ver CaptureService.freezeScreen) -
# quando presente, RECORTA dele em vez de rodar o grim de novo agora. Sem
# isso, um painel tipo a dock (que some sozinho quando o mouse passa longe
# da borda) podia ter desaparecido entre o momento em que o usuário via ele
# na tela e o momento em que a seleção terminava, ficando de fora do print
# final - o grim só roda DEPOIS do usuário escolher a região/janela. Com o
# arquivo já congelado antes de qualquer interação, o print final sempre
# reflete exatamente o que estava na tela quando a captura começou.
#
# Usage: capture-screenshot.sh <output_file> <geometry|""> <copy:0|1> <notify:0|1> [source_file]

set -euo pipefail

file="${1:?Uso: $(basename "$0") <output_file> <geometry> <copy> <notify>}"
geometry="${2:-}"
copy="${3:-0}"
notify="${4:-0}"
source_file="${5:-}"

mkdir -p "$(dirname "$file")"

if [ -n "$source_file" ] && [ -f "$source_file" ]; then
    if [ -n "$geometry" ]; then
        python3 - "$source_file" "$file" "$geometry" <<'PY'
import sys
from PIL import Image

src, out, geometry = sys.argv[1], sys.argv[2], sys.argv[3]
pos, size = geometry.split(" ")
x, y = (int(n) for n in pos.split(","))
w, h = (int(n) for n in size.split("x"))

Image.open(src).crop((x, y, x + w, y + h)).save(out)
PY
    else
        cp "$source_file" "$file"
    fi
elif [ -n "$geometry" ]; then
    grim -g "$geometry" "$file"
else
    grim "$file"
fi

[ "$copy" = "1" ] && wl-copy < "$file"
[ "$notify" = "1" ] && notify-send -i "$file" "Captura de tela" "Salva em $file"

exit 0
