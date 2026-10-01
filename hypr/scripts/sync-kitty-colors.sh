#!/usr/bin/env bash

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
out_file="$HOME/.config/kitty/theme_colors.conf"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$(dirname "$out_file")"

python3 - "$colors_file" "$out_file" <<'PY'
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path) as f:
    c = json.load(f)


def color(name):
    return c[name].lstrip("#")


kitty = f'''# Generated from quickshell's State/colors.json
# Do not edit by hand.

background #{color("background")}
foreground #{color("foreground")}

cursor #{color("accent")}
cursor_text_color #{color("background")}

selection_background #{color("accent")}
selection_foreground #{color("background")}

url_color #{color("accentAlt")}

# ANSI
color0 #{color("background")}
color1 #{color("danger")}
color2 #{color("success")}
color3 #{color("accentAlt")}
color4 #{color("accent")}
color5 #{color("accentAlt")}
color6 #{color("accentAlt")}
color7 #{color("foreground")}

color8 #{color("border")}
color9 #{color("danger")}
color10 #{color("success")}
color11 #{color("accentAlt")}
color12 #{color("accent")}
color13 #{color("accentAlt")}
color14 #{color("accentAlt")}
color15 #{color("foreground")}
'''

with open(out_path, "w") as f:
    f.write(kitty)
PY