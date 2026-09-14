#!/usr/bin/env bash
#
# Registra o wallpaper escolhido como o atual, manda o awww desenhar de
# verdade e regenera o tema a partir dele. Compartilhado por
# toggle-wallpaper.sh (escolha nova) e load-wallpaper.sh (recarrega a
# última, ex.: autostart do Hyprland), pra wallpaper exibido e tema
# aplicado nunca ficarem dessincronizados.
#
# Usage:
#   set-wallpaper.sh <path-to-image>

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
wallpaper="${1:?Uso: $(basename "$0") <caminho-da-imagem>}"

mkdir -p "$(dirname "$STATE_FILE")"

echo "$wallpaper" > "$STATE_FILE"

# Não deixa uma falha do awww (daemon fora do ar, socket ainda subindo)
# derrubar a regeneração do tema abaixo - as duas coisas são independentes.
if command -v awww >/dev/null 2>&1; then
    awww img "$wallpaper" || echo "awww: falhou ao trocar o wallpaper" >&2
fi

"$(dirname "$0")/apply-theme.sh" "$wallpaper"
