#!/usr/bin/env bash
#
# Re-applies whatever wallpaper toggle-wallpaper.sh set last, instead of
# picking a new random one. Meant for Hyprland's autostart, so the wallpaper
# and the quickshell/Hyprland theme colors always match what was showing
# before the last restart, rather than the theme reflecting a fresh random
# pick while awww/the state file still point at the old image.
#
# Usage:
#   load-wallpaper.sh

set -euo pipefail

STATE_FILE="$HOME/.cache/hypr/wallpaper_current"
script_dir="$(dirname "$0")"

if [ -s "$STATE_FILE" ] && [ -f "$(cat "$STATE_FILE")" ]; then
    "$script_dir/set-wallpaper.sh" "$(cat "$STATE_FILE")"
else
    "$script_dir/toggle-wallpaper.sh" random
fi
