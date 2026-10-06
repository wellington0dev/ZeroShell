#!/usr/bin/env bash
#
# Sincroniza as cores do GTK com o tema do Quickshell.
#
# Fonte:
#   ~/.config/quickshell/State/colors.json
#
# Saídas:
#   ~/.config/gtk-3.0/gtk.css
#   ~/.config/gtk-4.0/gtk.css
#

set -euo pipefail

colors_file="$HOME/.config/quickshell/State/colors.json"

gtk3_file="$HOME/.config/gtk-3.0/gtk.css"
gtk4_file="$HOME/.config/gtk-4.0/gtk.css"

[ -f "$colors_file" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p \
    "$(dirname "$gtk3_file")" \
    "$(dirname "$gtk4_file")"

python3 - "$colors_file" "$gtk3_file" "$gtk4_file" <<'PY'
import json
import sys

colors_path, gtk3_path, gtk4_path = sys.argv[1:]

with open(colors_path) as f:
    c = json.load(f)

background       = c["background"]
surface          = c["surface"]
surface_alt      = c["surfaceAlt"]
border           = c["border"]
foreground       = c["foreground"]
foreground_muted = c["foregroundMuted"]
accent           = c["accent"]
accent_alt       = c["accentAlt"]
danger           = c["danger"]
success          = c["success"]


css = f'''
/*
 * ZeroShell GTK Theme
 *
 * Generated from:
 * ~/.config/quickshell/State/colors.json
 *
 * DO NOT EDIT BY HAND.
 */


/* ===========================================================
 * COLOR PALETTE
 * ========================================================= */

@define-color zeroshell-background {background};
@define-color zeroshell-surface {surface};
@define-color zeroshell-surface-alt {surface_alt};
@define-color zeroshell-border {border};

@define-color zeroshell-foreground {foreground};
@define-color zeroshell-foreground-muted {foreground_muted};

@define-color zeroshell-accent {accent};
@define-color zeroshell-accent-alt {accent_alt};

@define-color zeroshell-danger {danger};
@define-color zeroshell-success {success};


/* ===========================================================
 * GLOBAL
 * ========================================================= */

* {{
    color: {foreground};
    background-color: transparent;
    border-color: {border};
}}


/* ===========================================================
 * WINDOWS
 * ========================================================= */

window,
window.background,
.background {{
    background-color: {background};
    color: {foreground};
}}


/* ===========================================================
 * FILE CHOOSER
 * ========================================================= */

filechooser,
filechooser.background {{
    background-color: {background};
    color: {foreground};
}}


/* ===========================================================
 * HEADERBAR
 * ========================================================= */

headerbar,
headerbar.titlebar {{
    background-color: {surface};
    color: {foreground};

    border: none;
    border-bottom: 1px solid {border};

    box-shadow: none;
    background-image: none;
}}


/* ===========================================================
 * HEADERBAR BUTTONS
 * ========================================================= */

headerbar button,
.titlebar button {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};
    background-image: none;
    box-shadow: none;
}}

headerbar button:hover,
.titlebar button:hover {{
    background-color: {surface_alt};
    color: {foreground};
}}

headerbar button:active,
headerbar button:checked,
.titlebar button:active,
.titlebar button:checked {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * ENTRIES / SEARCH
 * ========================================================= */

entry,
searchentry {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};
    background-image: none;
    box-shadow: none;
}}

entry:focus,
searchentry:focus,
entry:focus-within,
searchentry:focus-within {{
    border-color: {accent};
    box-shadow: 0 0 0 1px {accent};
}}


/* ===========================================================
 * FILE VIEW
 * ========================================================= */

.view,
.view.view,
treeview,
treeview.view,
filechooser .view {{
    background-color: {background};
    color: {foreground};

    border: none;
    background-image: none;
}}


/* ===========================================================
 * FILE VIEW — ROWS
 * ========================================================= */

.view row,
treeview row,
filechooser row {{
    background-color: transparent;
    color: {foreground};
}}

.view row:hover,
treeview row:hover,
filechooser row:hover {{
    background-color: {surface};
    color: {foreground};
}}

.view row:selected,
treeview row:selected,
filechooser row:selected {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * FILE VIEW — ALTERNATE
 * ========================================================= */

.view row:nth-child(even),
treeview row:nth-child(even) {{
    background-color: {surface};
}}

.view row:nth-child(even):hover,
treeview row:nth-child(even):hover {{
    background-color: {surface_alt};
}}


/* ===========================================================
 * SIDEBAR
 * ========================================================= */

sidebar,
.sidebar,
placessidebar,
placessidebar.sidebar {{
    background-color: {surface};
    color: {foreground};

    border: none;
    border-right: 1px solid {border};
    background-image: none;
}}


/* ===========================================================
 * SIDEBAR ROWS
 * ========================================================= */

sidebar row,
.sidebar row,
placessidebar row {{
    background-color: transparent;
    color: {foreground};

    border: none;
}}

sidebar row:hover,
.sidebar row:hover,
placessidebar row:hover {{
    background-color: {surface_alt};
    color: {foreground};
}}

sidebar row:selected,
.sidebar row:selected,
placessidebar row:selected {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * PATH / LOCATION BAR
 * ========================================================= */

.path-bar,
.path-bar button,
.location-bar,
.location-bar button {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};
    background-image: none;
    box-shadow: none;
}}

.path-bar button:hover,
.location-bar button:hover {{
    background-color: {surface_alt};
    color: {foreground};
}}

.path-bar button:checked,
.location-bar button:checked {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * BUTTONS
 * ========================================================= */

button {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};

    background-image: none;
    box-shadow: none;
}}

button:hover {{
    background-color: {surface_alt};
    color: {foreground};
}}

button:active,
button:checked {{
    background-color: {accent};
    color: {background};
}}

button:disabled {{
    background-color: {surface};
    color: {foreground_muted};
    border-color: {border};
}}


/* ===========================================================
 * DIALOG ACTION AREA
 * ========================================================= */

dialog-action-area,
.action-area {{
    background-color: {surface};
    color: {foreground};

    border-top: 1px solid {border};
}}


/* ===========================================================
 * LISTS
 * ========================================================= */

list,
listview {{
    background-color: {background};
    color: {foreground};
}}

list row,
listview row {{
    background-color: transparent;
    color: {foreground};
}}

list row:hover,
listview row:hover {{
    background-color: {surface};
}}

list row:selected,
listview row:selected {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * SELECTION
 * ========================================================= */

selection {{
    background-color: {accent};
    color: {background};
}}


/* ===========================================================
 * CHECKBOX / RADIO
 * ========================================================= */

checkbutton:checked,
radiobutton:checked {{
    color: {accent};
}}


/* ===========================================================
 * LINKS
 * ========================================================= */

link {{
    color: {accent_alt};
}}

link:hover {{
    color: {accent};
}}


/* ===========================================================
 * MENUS / POPOVERS
 * ========================================================= */

menu,
.menu,
popover,
popover.background {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};
    background-image: none;
    box-shadow: none;
}}

menuitem:hover,
.menuitem:hover {{
    background-color: {surface_alt};
    color: {foreground};
}}


/* ===========================================================
 * SCROLLBARS
 * ========================================================= */

scrollbar {{
    background-color: {background};
}}

scrollbar slider {{
    background-color: {border};

    border: none;
}}

scrollbar slider:hover {{
    background-color: {foreground_muted};
}}

scrollbar slider:active {{
    background-color: {accent};
}}


/* ===========================================================
 * SEPARATORS
 * ========================================================= */

separator {{
    background-color: {border};
}}


/* ===========================================================
 * TOOLTIPS
 * ========================================================= */

tooltip,
tooltip.background {{
    background-color: {surface};
    color: {foreground};

    border: 1px solid {border};
}}


/* ===========================================================
 * DESTRUCTIVE / SUCCESS
 * ========================================================= */

.destructive-action {{
    background-color: {danger};
    color: {background};
}}

.success {{
    color: {success};
}}
'''


# GTK 3
with open(gtk3_path, "w") as f:
    f.write(css)


# GTK 4
with open(gtk4_path, "w") as f:
    f.write(css)


print("GTK sincronizado:")
print(f"  GTK 3: {gtk3_path}")
print(f"  GTK 4: {gtk4_path}")
PY