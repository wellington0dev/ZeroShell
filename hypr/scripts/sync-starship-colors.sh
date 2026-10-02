#!/usr/bin/env bash
#
# Gera o starship.toml a partir das cores do Quickshell.
#
# Fonte:
#   ~/.config/quickshell/State/colors.json
#
# Saída:
#   ~/.config/starship.toml
#
# O layout/configuração do Starship é preservado.
# Apenas as cores são sincronizadas com o tema do Quickshell.
#

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
out_file="$HOME/.config/starship.toml"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$(dirname "$out_file")"

python3 - "$colors_file" "$out_file" <<'PY'
import json
import sys

colors_path, out_path = sys.argv[1], sys.argv[2]

with open(colors_path) as f:
    c = json.load(f)


# ============================================================
# Quickshell → Starship
# ============================================================

background      = c["background"]
surface         = c["surface"]
surface_alt     = c["surfaceAlt"]
border          = c["border"]
foreground      = c["foreground"]
foreground_muted = c["foregroundMuted"]
accent          = c["accent"]
accent_alt      = c["accentAlt"]
danger          = c["danger"]
success         = c["success"]


theme = f'''# ============================================================
# Starship Theme
# Generated from quickshell's State/colors.json
# Do not edit by hand.
#
# Source:
#   ~/.config/quickshell/State/colors.json
# ============================================================

# Don't print a new line at the start of the prompt
add_newline = false

# Pipes ╰─ ╭─
# Powerline symbols                                    
# Wedges 🭧🭒 🭣🭧🭓
# Random noise 🬖🬥🬔🬗
# Cool stuff 󰜥   

# format = """
# $directory $fill $git_branch $cmd_duration
#  $character"""
format = """
$cmd_duration $directory$git_branch
  $character"""

[fill]
symbol = '-'
style = 'fg:{border}'

# Replace the "❯" symbol in the prompt with "➜"
[character]
success_symbol = "[ ](bold fg:{foreground_muted})"
error_symbol = "[ ](bold fg:{danger})"

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

[git_branch]
style = "bg:{surface}"
symbol = "󰘬"
truncation_length = 12
truncation_symbol = ""
format = " 󰜥 [](bold fg:{surface})[$symbol $branch(:$remote_branch)](fg:{foreground} bg:{surface})[ ](bold fg:{surface})"

[git_commit]
commit_hash_length = 4
tag_symbol = " "

[git_state]
format = '[\\($state( $progress_current of $progress_total)\\)]($style) '
cherry_pick = "[🍒 PICKING](bold {danger})"

[git_status]
conflicted = " 🏳 "
ahead = " 🏎💨 "
behind = " 😰 "
diverged = " 😵 "
untracked = " 🤷 ‍"
stashed = " 📦 "
modified = " 📝 "
staged = '[++\\($count\\)]({success})'
renamed = " ✍️ "
deleted = " 🗑 "

[hostname]
ssh_only = false
format =  "[•$hostname](bg:{surface} bold fg:{foreground})[](bold fg:{surface})"
trim_at = ".companyname.com"
disabled = false

[line_break]
disabled = false

[memory_usage]
disabled = true
threshold = -1
symbol = " "
style = "bold dimmed {success}"

[time]
disabled = true
format = '🕙[\\[ $time \\]]($style) '
time_format = "%T"

[username]
style_user = "bold bg:{surface} fg:{foreground}"
style_root = "{danger} bold"
format = "[](bold fg:{surface})[$user]($style)"
disabled = false
show_always = true

[directory]
home_symbol = " "
read_only = "  "
style = "bg:{background} fg:{foreground_muted}"
truncation_length = 2
truncation_symbol = ".../"
format = '[](bold fg:{background})[󰉋 → $path]($style)[](bold fg:{background})'


[directory.substitutions]
"Desktop" = "  "
"Documents" = "  "
"Downloads" = "  "
"Music" = " 󰎈 "
"Pictures" = "  "
"Videos" = "  "
"GitHub" = " 󰊤 "

[cmd_duration]
min_time = 0
format = '[](bold fg:{surface})[󰪢 $duration](bold bg:{surface} fg:{foreground})[](bold fg:{surface})'
'''

with open(out_path, "w") as f:
    f.write(theme)
PY

echo "Starship sincronizado:"
echo "  $out_file"