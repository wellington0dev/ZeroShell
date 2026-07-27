#!/usr/bin/env bash
#
# Applies a specific wallpaper image via awww, records it as the current one,
# and regenerates the color theme from it. Shared by toggle-wallpaper.sh (new
# pick) and load-wallpaper.sh (reload the last one, e.g. on Hyprland startup)
# so the displayed wallpaper and the applied theme never drift apart.
#
# Usage:
#   set-wallpaper.sh <path-to-image>

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
wallpaper="${1:?Uso: $(basename "$0") <caminho-da-imagem>}"

mkdir -p "$(dirname "$STATE_FILE")"

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon &
    for _ in $(seq 1 20); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

awww img "$wallpaper" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-step 90 \
    --transition-fps 30

echo "$wallpaper" > "$STATE_FILE"

"$(dirname "$0")/apply-theme.sh" "$wallpaper"
