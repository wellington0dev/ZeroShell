#!/usr/bin/env bash

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
out_file="$HOME/.config/rofi/theme_colors.rasi"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$(dirname "$out_file")"

python3 - "$colors_file" "$out_file" <<'PY'
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path) as f:
    c = json.load(f)


theme = f'''/* ROFI SQUARED THEME */
/* Generated from quickshell's State/colors.json */
/* Do not edit by hand. */

* {{
    font:   "FiraCode Nerd Font Medium 12";

    bg0:     {c["background"]};
    bg1:     {c["surface"]};
    fg0:     {c["foreground"]};

    accent-color:     {c["accent"]};
    urgent-color:     {c["danger"]};

    background-color:   transparent;
    text-color:         @fg0;

    margin:     0;
    padding:    0;
    spacing:    0;
}}

window {{
    location:   center;
    width:      480;

    background-color:   @bg0;
}}

inputbar {{
    spacing:    8px;
    padding:    8px;

    background-color:   @bg1;
}}

prompt, entry, element-icon, element-text {{
    vertical-align: 0.5;
}}

prompt {{
    text-color: @accent-color;
}}

textbox {{
    padding:            8px;
    background-color:   @bg1;
}}

listview {{
    padding:    4px 0;
    lines:      8;
    columns:    1;

    fixed-height:   false;
}}

element {{
    padding:    8px;
    spacing:    8px;
}}

element normal normal {{
    text-color: @fg0;
}}

element normal urgent {{
    text-color: @urgent-color;
}}

element normal active {{
    text-color: @accent-color;
}}

element alternate active {{
    text-color: @accent-color;
}}

element selected {{
    text-color: @bg0;
}}

element selected normal, element selected active {{
    background-color:   @accent-color;
}}

element selected urgent {{
    background-color:   @urgent-color;
}}

element-icon {{
    size:   0.8em;
}}

element-text {{
    text-color: inherit;
}}
'''

with open(out_path, "w") as f:
    f.write(theme)
PY