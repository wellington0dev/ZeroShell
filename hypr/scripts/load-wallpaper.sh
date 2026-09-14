#!/usr/bin/env bash
#
# Garante que o awww-daemon esteja de pé e desenhando o wallpaper atual -
# chamado no autostart do Hyprland, logo depois de subir o "qs" (ver
# hypr/modules/autostart.lua). O daemon do awww sobe "em branco" a cada
# reinício (não lembra sozinho do último wallpaper), por isso este script
# sempre manda redesenhar, não só na primeira vez. Inicia o daemon aqui
# mesmo, em vez de uma linha própria em autostart.lua, pra não depender da
# ordem dos exec_cmd - inicia, dá um respiro pro socket subir, só então
# manda desenhar.
#
# Usage:
#   load-wallpaper.sh

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
script_dir="$(dirname "$0")"

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon &
    disown
    sleep 0.3
fi

if [ ! -s "$STATE_FILE" ] || [ ! -f "$(cat "$STATE_FILE")" ]; then
    "$script_dir/toggle-wallpaper.sh" random
else
    "$script_dir/set-wallpaper.sh" "$(cat "$STATE_FILE")"
fi
