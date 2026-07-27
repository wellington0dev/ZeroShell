#!/usr/bin/env bash
#
# Regenerates theme_colors.lua straight from quickshell's own
# State/colors.json, so Hyprland's window borders always match whatever
# quickshell is showing - whether that palette came from matugen or was
# customized by hand in the quickshell settings UI (Aparência > Personalizar).
#
# Called by apply-theme.sh after matugen runs, and by quickshell itself
# (Theme/Colors.qml) right after every manual color edit.
#
# Usage:
#   sync-hypr-colors.sh

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
out_file="$HOME/.config/hypr/theme_colors.lua"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$colors_file" "$out_file" <<'PY'
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path) as f:
    c = json.load(f)


def strip(hex_color):
    return hex_color.lstrip("#")


lua = f'''-- Generated from quickshell's State/colors.json - do not edit by hand.
-- Source: ~/.config/hypr/scripts/sync-hypr-colors.sh

return {{
    active_border_1 = "rgba({strip(c["accent"])}ee)",
    active_border_2 = "rgba({strip(c["accentAlt"])}ee)",
    inactive_border = "rgba({strip(c["border"])}aa)",
}}
'''

with open(out_path, "w") as f:
    f.write(lua)
PY

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
