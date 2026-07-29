#!/usr/bin/env bash
#
# Regenera hypr/window_radius.lua com o valor de "rounding" passado e
# recarrega o Hyprland. Chamado por RadiusCustomizer.qml (Configurações >
# Aparência > Raio) sempre que o slider "Janelas" muda - mesmo padrão do
# apply-theme.sh (matugen) pra theme_colors.lua, só que pra um número em vez
# de cores.
#
# Usage:
#   set-window-radius.sh <valor-em-px>

set -euo pipefail

rounding="${1:?Uso: $(basename "$0") <valor-em-px>}"
out_file="$HOME/.config/hypr/window_radius.lua"

cat > "$out_file" <<EOF
-- Gerado pela aba Configurações > Aparência > Raio (RadiusCustomizer.qml no
-- quickshell) sempre que "Janelas" muda. Não edite à mão - mude por lá.
return {
    rounding = $rounding,
}
EOF

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
