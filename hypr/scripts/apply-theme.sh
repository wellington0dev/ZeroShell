#!/usr/bin/env bash
#
# Regenerate the quickshell color data (~/.config/quickshell/State/colors.json)
# from a wallpaper image using matugen, then derive the Hyprland border
# colors (~/.config/hypr/theme_colors.lua) from that same file via
# sync-hypr-colors.sh. Quickshell picks up colors.json live via a FileView
# (no reload needed); Hyprland's Lua config doesn't hot-reload, so
# sync-hypr-colors.sh reloads it explicitly.
#
# Usage:
#   apply-theme.sh <path-to-image>

set -euo pipefail

wallpaper="${1:?Uso: $(basename "$0") <caminho-da-imagem>}"

# The quickshell theme settings page ("Personalizar") flips this off when the
# user picks their own colors, so wallpaper/keybind-driven theme changes stop
# overwriting them until "Cores do wallpaper" is switched back on.
mode_file="$HOME/.config/quickshell/State/theme-mode.json"
if [ -f "$mode_file" ] && command -v python3 >/dev/null 2>&1; then
    use_wallpaper_colors="$(python3 -c "
import json
try:
    with open('$mode_file') as f:
        print('yes' if json.load(f).get('useWallpaperColors', True) else 'no')
except Exception:
    print('yes')
")"
    if [ "$use_wallpaper_colors" = "no" ]; then
        echo "Cores personalizadas ativas, pulando geração de tema a partir do wallpaper." >&2
        exit 0
    fi
fi

if ! command -v matugen >/dev/null 2>&1; then
    echo "matugen não está instalado, pulando tema do quickshell." >&2
    exit 0
fi

script_dir="$(dirname "$0")"
# quickshell-colors.json always reads wallAccent2, so this needs a value even
# when python-pillow isn't installed - falls back to a neutral gray that
# matugen still tints/lightens like any other color.
extra_colors='{"wallAccent2":{"color":"#7c7c7c"}}'
if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" >/dev/null 2>&1; then
    extra_colors="$(python3 "$script_dir/extract-colors.py" "$wallpaper")"
fi

matugen image "$wallpaper" --source-color-index 0 --import-json-string "$extra_colors"

"$script_dir/sync-hypr-colors.sh"
