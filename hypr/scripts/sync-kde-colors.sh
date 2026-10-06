#!/usr/bin/env bash
#
# Sincroniza o esquema de cores KDE/Qt com o tema do Quickshell.
#
# Fonte:
#   ~/.config/quickshell/State/colors.json
#
# Saídas:
#   ~/.local/share/color-schemes/ZeroShell.colors
#   ~/.config/kdeglobals
#

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"
scheme_dir="$HOME/.local/share/color-schemes"
scheme_file="$scheme_dir/ZeroShell.colors"
kdeglobals="$HOME/.config/kdeglobals"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$scheme_dir"

python3 - "$colors_file" "$scheme_file" "$kdeglobals" <<'PY'
import json
import shutil
import subprocess
import sys

colors_path, scheme_path, kdeglobals_path = sys.argv[1:]


# ============================================================
# Carrega colors.json
# ============================================================

with open(colors_path) as f:
    c = json.load(f)


# ============================================================
# Helpers
# ============================================================

def rgb(hex_color):
    h = hex_color.lstrip("#")

    return tuple(
        int(h[i:i + 2], 16)
        for i in (0, 2, 4)
    )


def color(value):
    r, g, b = value
    return f"{r},{g},{b}"


# ============================================================
# Quickshell colors → RGB
# ============================================================

bg = rgb(c["background"])
surface = rgb(c["surface"])
surface_alt = rgb(c["surfaceAlt"])
border = rgb(c["border"])

fg = rgb(c["foreground"])
fg_muted = rgb(c["foregroundMuted"])

accent = rgb(c["accent"])
accent_alt = rgb(c["accentAlt"])

danger = rgb(c["danger"])
success = rgb(c["success"])


# ============================================================
# KDE Color Scheme
# ============================================================

scheme = f"""[ColorEffects:Disabled]
Color={color(fg_muted)}
ColorAmount=0
ColorEffect=0
ContrastAmount=0
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color={color(fg_muted)}
ColorAmount=0
ColorEffect=0
ContrastAmount=0
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundNormal={color(surface)}
BackgroundAlternate={color(surface_alt)}
ForegroundNormal={color(fg)}
ForegroundActive={color(bg)}
ForegroundInactive={color(fg_muted)}
ForegroundNegative={color(bg)}
ForegroundPositive={color(bg)}
ForegroundNeutral={color(bg)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:Complementary]
BackgroundNormal={color(surface_alt)}
BackgroundAlternate={color(surface)}
ForegroundNormal={color(fg)}
ForegroundActive={color(bg)}
ForegroundInactive={color(fg_muted)}
ForegroundNegative={color(bg)}
ForegroundPositive={color(bg)}
ForegroundNeutral={color(bg)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:Header]
BackgroundNormal={color(surface)}
BackgroundAlternate={color(surface_alt)}
ForegroundNormal={color(fg)}
ForegroundActive={color(bg)}
ForegroundInactive={color(fg_muted)}
ForegroundNegative={color(bg)}
ForegroundPositive={color(bg)}
ForegroundNeutral={color(bg)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:Selection]
BackgroundNormal={color(accent)}
BackgroundAlternate={color(accent_alt)}
ForegroundNormal={color(bg)}
ForegroundInactive={color(bg)}
ForegroundActive={color(bg)}
ForegroundNegative={color(bg)}
ForegroundPositive={color(bg)}
ForegroundNeutral={color(bg)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:Tooltip]
BackgroundNormal={color(surface)}
BackgroundAlternate={color(surface_alt)}
ForegroundNormal={color(fg)}
ForegroundInactive={color(fg_muted)}
ForegroundActive={color(bg)}
ForegroundNegative={color(bg)}
ForegroundPositive={color(bg)}
ForegroundNeutral={color(bg)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:View]
BackgroundNormal={color(bg)}
BackgroundAlternate={color(surface)}
ForegroundNormal={color(fg)}
ForegroundInactive={color(fg_muted)}
ForegroundActive={color(accent)}
ForegroundNegative={color(danger)}
ForegroundPositive={color(success)}
ForegroundNeutral={color(accent_alt)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[Colors:Window]
BackgroundNormal={color(bg)}
BackgroundAlternate={color(surface)}
ForegroundNormal={color(fg)}
ForegroundInactive={color(fg_muted)}
ForegroundActive={color(accent)}
ForegroundNegative={color(danger)}
ForegroundPositive={color(success)}
ForegroundNeutral={color(accent_alt)}
DecorationFocus={color(accent)}
DecorationHover={color(accent_alt)}

[General]
ColorScheme=ZeroShell
Name=ZeroShell
shadeSortColumn=true
"""


# ============================================================
# Grava ZeroShell.colors
# ============================================================

with open(scheme_path, "w") as f:
    f.write(scheme)

print(f"KDE color scheme gerado: {scheme_path}")


# ============================================================
# Atualiza kdeglobals
# ============================================================

kwriteconfig6 = shutil.which("kwriteconfig6")

if kwriteconfig6:

    def write(group, key, value):
        subprocess.run(
            [
                kwriteconfig6,
                "--file",
                kdeglobals_path,
                "--group",
                group,
                "--key",
                key,
                value,
            ],
            check=True,
        )


    # --------------------------------------------------------
    # General
    # --------------------------------------------------------

    write("General", "ColorScheme", "ZeroShell")


    # --------------------------------------------------------
    # View
    # --------------------------------------------------------

    view = {
        "BackgroundNormal": bg,
        "BackgroundAlternate": surface,

        "ForegroundNormal": fg,
        "ForegroundInactive": fg_muted,
        "ForegroundActive": accent,
        "ForegroundNegative": danger,
        "ForegroundPositive": success,
        "ForegroundNeutral": accent_alt,

        "DecorationFocus": accent,
        "DecorationHover": accent_alt,
    }

    for key, value in view.items():
        write("Colors:View", key, color(value))


    # --------------------------------------------------------
    # Window
    # --------------------------------------------------------

    window = {
        "BackgroundNormal": bg,
        "BackgroundAlternate": surface,

        "ForegroundNormal": fg,
        "ForegroundInactive": fg_muted,
        "ForegroundActive": accent,
        "ForegroundNegative": danger,
        "ForegroundPositive": success,
        "ForegroundNeutral": accent_alt,

        "DecorationFocus": accent,
        "DecorationHover": accent_alt,
    }

    for key, value in window.items():
        write("Colors:Window", key, color(value))


    # --------------------------------------------------------
    # Button
    #
    # Estados de destaque usam background como texto para
    # garantir contraste.
    # --------------------------------------------------------

    button = {
        "BackgroundNormal": surface,
        "BackgroundAlternate": surface_alt,

        "ForegroundNormal": fg,
        "ForegroundActive": bg,
        "ForegroundInactive": fg_muted,

        "ForegroundNegative": bg,
        "ForegroundPositive": bg,
        "ForegroundNeutral": bg,

        "DecorationFocus": accent,
        "DecorationHover": accent_alt,
    }

    for key, value in button.items():
        write("Colors:Button", key, color(value))


    # --------------------------------------------------------
    # Selection
    # --------------------------------------------------------

    selection = {
        "BackgroundNormal": accent,
        "BackgroundAlternate": accent_alt,

        "ForegroundNormal": bg,
        "ForegroundInactive": bg,
        "ForegroundActive": bg,
        "ForegroundNegative": bg,
        "ForegroundPositive": bg,
        "ForegroundNeutral": bg,

        "DecorationFocus": accent,
        "DecorationHover": accent_alt,
    }

    for key, value in selection.items():
        write("Colors:Selection", key, color(value))


    print(f"KDE globals atualizado: {kdeglobals_path}")

else:
    print("kwriteconfig6 não encontrado; kdeglobals não foi atualizado.")
PY

echo
echo "KDE/Qt sincronizado."
echo "  Scheme: $scheme_file"
echo "  Config: $kdeglobals"