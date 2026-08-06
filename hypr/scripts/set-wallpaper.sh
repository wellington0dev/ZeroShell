#!/usr/bin/env bash
#
# Registra o wallpaper escolhido como o atual e regenera o tema a partir
# dele. Quem desenha o wallpaper de verdade é o próprio quickshell
# (Modules/Wallpaper/WallpaperWindow.qml, via FileView com watchChanges no
# mesmo STATE_FILE abaixo) - este script só escreve o estado, não desenha
# nada. Compartilhado por toggle-wallpaper.sh (escolha nova) e
# load-wallpaper.sh (recarrega a última, ex.: autostart do Hyprland), pra
# wallpaper exibido e tema aplicado nunca ficarem dessincronizados.
#
# Usage:
#   set-wallpaper.sh <path-to-image>

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
wallpaper="${1:?Uso: $(basename "$0") <caminho-da-imagem>}"

mkdir -p "$(dirname "$STATE_FILE")"

echo "$wallpaper" > "$STATE_FILE"

"$(dirname "$0")/apply-theme.sh" "$wallpaper"
