#!/usr/bin/env bash
#
# Imprime a geometria "X,Y WxH" pro alvo pedido, no formato que grim/wf-recorder
# esperam em "-g". Para "fullscreen" não imprime nada (grim/wf-recorder sem -g
# já capturam a saída inteira).
#
# region: deixa o usuário arrastar uma seleção livre na tela via slurp.
# window: deixa o usuário CLICAR na janela desejada via slurp -r, que
#   restringe a seleção às caixas (janelas reais, vindas do hyprctl) passadas
#   por stdin - assim o clique gruda certinho no contorno da janela clicada,
#   em vez de sempre pegar a janela que estava em foco antes de abrir o menu.
#
# Se o usuário cancelar o slurp (Esc), o comando sai com erro e nada é
# impresso - quem chama este script deve tratar saída vazia como "cancelado".
#
# Usage: capture-geometry.sh <region|window|fullscreen>

set -euo pipefail

target="${1:?Uso: $(basename "$0") <region|window|fullscreen>}"

case "$target" in
    region)
        # "< /dev/null" é essencial aqui: o slurp sem "-r" ainda assim tenta
        # ler stdin, e quando este script é chamado pelo Quickshell (em vez
        # de um terminal), o stdin herdado é um pipe aberto que nunca recebe
        # EOF - o slurp fica pendurado pra sempre esperando por ele. No
        # terminal isso passava despercebido porque o stdin já vinha
        # fechado/redirecionado.
        slurp < /dev/null
        ;;
    window)
        hyprctl clients -j | python3 -c '
import json
import sys

for c in json.load(sys.stdin):
    if not c.get("mapped") or c.get("hidden"):
        continue
    x, y = c["at"]
    w, h = c["size"]
    print(f"{x},{y} {w}x{h}")
' | slurp -r
        ;;
    fullscreen)
        ;;
    *)
        echo "Alvo desconhecido: $target" >&2
        exit 1
        ;;
esac
