#!/usr/bin/env bash
#
# Sincroniza as cores do Neovim com o tema do Quickshell.
#
# Fonte:
#   ~/.config/quickshell/State/colors.json
#
# Saída:
#   ~/.config/nvim/lua/zeroshell_colors.lua
#
# Não edite zeroshell_colors.lua manualmente.
#

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
out_file="$HOME/.config/nvim/lua/zeroshell_colors.lua"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$(dirname "$out_file")"

python3 - "$colors_file" "$out_file" <<'PY'
import json
import sys

colors_path, out_path = sys.argv[1:]

with open(colors_path) as f:
    c = json.load(f)


def lua_string(value):
    return f'"{value}"'


lua = f'''-- Generated from quickshell's State/colors.json
-- Do not edit by hand.
--
-- Source:
--   ~/.config/quickshell/State/colors.json

local M = {{

    background = {lua_string(c["background"])},
    surface = {lua_string(c["surface"])},
    surface_alt = {lua_string(c["surfaceAlt"])},
    border = {lua_string(c["border"])},

    foreground = {lua_string(c["foreground"])},
    foreground_muted = {lua_string(c["foregroundMuted"])},

    accent = {lua_string(c["accent"])},
    accent_alt = {lua_string(c["accentAlt"])},

    danger = {lua_string(c["danger"])},
    success = {lua_string(c["success"])},
}}

return M
'''

with open(out_path, "w") as f:
    f.write(lua)

print(f"Neovim colors sincronizado: {out_path}")
PY

