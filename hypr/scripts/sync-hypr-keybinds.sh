#!/usr/bin/env bash
#
# Regenera keybinds.lua a partir de quickshell/State/keybinds.json - mesmo
# padrão de sync-hypr-colors.sh (JSON é a fonte de verdade do lado
# quickshell, o .lua gerado é só o que o Hyprland de fato lê). Chamado pela
# aba "Atalhos" das Configurações logo depois de qualquer troca de tecla
# ou do modificador principal.
#
# Usage:
#   sync-hypr-keybinds.sh

set -euo pipefail

keybinds_file="$HOME/.config/quickshell/State/keybinds.json"
out_file="$HOME/.config/hypr/keybinds.lua"

[ -f "$keybinds_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$keybinds_file" "$out_file" <<'PY'
import json
import sys

kb_path, out_path = sys.argv[1], sys.argv[2]

with open(kb_path) as f:
    d = json.load(f)

def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

main_mod = d.get("mainMod") or "SUPER"
overrides = {o["id"]: o["keys"] for o in d.get("overrides", []) if o.get("id") and o.get("keys")}
custom_binds = [b for b in d.get("customBinds", []) if b.get("id") and b.get("command")]

lines = [
    "-- Generated from quickshell's State/keybinds.json - do not edit by hand.",
    "-- Source: ~/.config/hypr/scripts/sync-hypr-keybinds.sh",
    "",
    "return {",
    f'    main_mod = "{main_mod}",',
    "    overrides = {",
]
for action_id, keys in overrides.items():
    keys_lua = ", ".join(f'"{k}"' for k in keys)
    lines.append(f'        {action_id} = {{ {keys_lua} }},')
lines.append("    },")
lines.append("    custom_binds = {")
for bind in custom_binds:
    keys_lua = ", ".join(lua_str(k) for k in bind.get("keys", []))
    lines.append(f'        {{ keys = {{ {keys_lua} }}, command = {lua_str(bind["command"])} }},')
lines.append("    },")
lines.append("}")

with open(out_path, "w") as f:
    f.write("\n".join(lines) + "\n")
PY

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
