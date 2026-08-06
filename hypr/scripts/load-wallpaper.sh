#!/usr/bin/env bash
#
# Garante que sempre exista um wallpaper - chamado no autostart do Hyprland,
# logo depois de subir o "qs" (ver hypr/modules/autostart.lua). Não precisa
# reaplicar nada no caso comum: o quickshell lê ~/.cache/hypr/wallpaper_current
# sozinho assim que sobe (Modules/Wallpaper/WallpaperWindow.qml, via
# FileView) e os arquivos de tema (colors.json, theme_colors.lua) já ficaram
# persistidos da última troca - isso só existia antes porque o awww (extinto,
# ver set-wallpaper.sh) começava "em branco" a cada reinício e precisava que
# alguém mandasse desenhar de novo. Só entra em ação no primeiro uso de
# verdade (arquivo de estado ausente ou apontando pra um arquivo que não
# existe mais), escolhendo um wallpaper aleatório.
#
# Usage:
#   load-wallpaper.sh

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
script_dir="$(dirname "$0")"

if [ ! -s "$STATE_FILE" ] || [ ! -f "$(cat "$STATE_FILE")" ]; then
    "$script_dir/toggle-wallpaper.sh" random
fi
