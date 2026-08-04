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
# overwriting them until "Cores do wallpaper" is switched back on. The same
# file also carries "schemeType" (qual "--type" do matugen usar pra derivar
# os tons neutros) e "colorMode" (claro/escuro, "--mode" do matugen) - ver
# aba "Cores do wallpaper" nas Configurações, WallpaperGrid.qml.
mode_file="$HOME/.config/quickshell/State/theme-mode.json"
scheme_type="scheme-neutral"
color_mode="dark"
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

    scheme_type="$(python3 -c "
import json
try:
    with open('$mode_file') as f:
        print(json.load(f).get('schemeType') or 'scheme-neutral')
except Exception:
    print('scheme-neutral')
")"

    color_mode="$(python3 -c "
import json
try:
    with open('$mode_file') as f:
        print(json.load(f).get('colorMode') or 'dark')
except Exception:
    print('dark')
")"
fi

if ! command -v matugen >/dev/null 2>&1; then
    echo "matugen não está instalado, pulando tema do quickshell." >&2
    exit 0
fi

script_dir="$(dirname "$0")"
# quickshell-colors.json always reads wallAccent1/wallAccent2, so these need
# a value even when python-pillow isn't installed - falls back to neutral
# grays (darker for light mode, so it stays legible against a light
# background - matugen só recebe o hex pronto, não ajusta mais lightness
# nenhuma pra accent/accentAlt, ver extract-colors.py).
extra_colors='{"wallAccent1":{"color":"#7c7c7c"},"wallAccent2":{"color":"#7c7c7c"}}'
[ "$color_mode" = "light" ] && extra_colors='{"wallAccent1":{"color":"#595959"},"wallAccent2":{"color":"#595959"}}'
if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" >/dev/null 2>&1; then
    extra_colors="$(python3 "$script_dir/extract-colors.py" "$wallpaper" "$color_mode" "$scheme_type")"
fi

# Fundo/superfície/borda/texto/accent/accentAlt vêm TODOS de
# extract-colors.py agora (amostra real da imagem + lightness/saturação
# alvo, incluindo o "--type" acima como multiplicador de saturação - ver
# SCHEME_SATURATION lá), não dos papéis nativos do matugen (colors.*) - só
# "danger"/"success" no template ainda leem "colors.*" de verdade, e são os
# únicos que o "--type" abaixo ainda afeta diretamente via matugen. O
# template não pina o próprio `type` (removido de propósito) então essa
# flag da CLI é quem manda nesses dois - um `type` no nível do template
# ganharia dela, não o contrário.
matugen image "$wallpaper" --source-color-index 0 --type "$scheme_type" --mode "$color_mode" --import-json-string "$extra_colors"

"$script_dir/sync-hypr-colors.sh"
