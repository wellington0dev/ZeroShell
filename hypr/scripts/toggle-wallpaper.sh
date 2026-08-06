#!/usr/bin/env bash
#
# Cycle or randomize the wallpaper from ~/Wallpapers. Picks the image and
# hands it to set-wallpaper.sh, which just records it as current and
# regenerates the theme - the quickshell itself renders the wallpaper
# (Modules/Wallpaper/WallpaperWindow.qml).
#
# Usage:
#   toggle-wallpaper.sh           # random wallpaper (default)
#   toggle-wallpaper.sh random    # random wallpaper
#   toggle-wallpaper.sh next      # next wallpaper, alphabetical order
#   toggle-wallpaper.sh prev      # previous wallpaper, alphabetical order

set -euo pipefail

WALLPAPER_DIR="$HOME/Wallpapers"
STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
MODE="${1:-random}"

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
    | sort)

if [ "${#WALLPAPERS[@]}" -eq 0 ]; then
    notify-send "Wallpaper" "Nenhuma imagem encontrada em $WALLPAPER_DIR" 2>/dev/null || true
    echo "Nenhuma imagem encontrada em $WALLPAPER_DIR" >&2
    exit 1
fi

current=""
[ -f "$STATE_FILE" ] && current="$(cat "$STATE_FILE")"

current_index=-1
for i in "${!WALLPAPERS[@]}"; do
    [ "${WALLPAPERS[$i]}" = "$current" ] && current_index="$i"
done

case "$MODE" in
    next)
        index=$(((current_index + 1) % ${#WALLPAPERS[@]}))
        ;;
    prev)
        index=$(((current_index - 1 + ${#WALLPAPERS[@]}) % ${#WALLPAPERS[@]}))
        ;;
    random)
        index=$((RANDOM % ${#WALLPAPERS[@]}))
        if [ "${#WALLPAPERS[@]}" -gt 1 ]; then
            while [ "$index" -eq "$current_index" ]; do
                index=$((RANDOM % ${#WALLPAPERS[@]}))
            done
        fi
        ;;
    *)
        echo "Uso: $(basename "$0") [random|next|prev]" >&2
        exit 1
        ;;
esac

"$(dirname "$0")/set-wallpaper.sh" "${WALLPAPERS[$index]}"
