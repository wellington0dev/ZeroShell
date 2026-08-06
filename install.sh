#!/usr/bin/env bash
#
# Instala as dependências usadas por este setup Hyprland + quickshell,
# copia as configs de ~/ZeroShell pra ~/.config (CONFIG_DIRS) e os
# scripts do setup pra lá também (SCRIPT_FILES), com base nos arrays
# em dirs.sh. Cópia de verdade, não symlink - depois de instalado,
# ~/.config fica independente do clone em ~/ZeroShell (dá pra até
# apagar ~/ZeroShell depois). Quem quiser mandar mudanças feitas em
# ~/.config de volta pro repositório usa ./update.sh (caminho inverso).
#
# Usage:
#   ./install.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/dirs.sh"

PACMAN_PKGS=(
    hyprland          # compositor
    quickshell        # shell (qs), usado no autostart e no bar/sidebar (também renderiza o wallpaper)
    matugen           # gera o tema do quickshell a partir do wallpaper
    python-pillow     # extract-colors.py, pega uma 2a cor dominante do wallpaper
    kitty             # terminal
    dolphin           # file manager
    playerctl         # media keys
    wireplumber       # wpctl, controle de audio
    brightnessctl     # brilho da tela
    libnotify         # notify-send
    grim              # screenshot
    cava              # terminal sound view    
    ttf-jetbrains-mono-nerd # fonte do shell (qs.Theme.Colors.fontFamily), com os glifos de ícone
    python-pam
)

echo "==> Instalando pacotes oficiais..."
sudo pacman -S --needed "${PACMAN_PKGS[@]}"

echo "==> Copiando configs para $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

for dir in "${CONFIG_DIRS[@]}"; do
    src="$DOTS_DIR/$dir"
    dest="$CONFIG_DIR/$dir"

    if [[ ! -e "$src" ]]; then
        echo "  !! $dir não existe em $DOTS_DIR, pulando"
        continue
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  -> $dir já existe em $CONFIG_DIR, fazendo backup em $backup"
        mv "$dest" "$backup"
    fi

    cp -a "$src" "$dest"
    echo "  -> $dir copiado"
done

echo "==> Copiando scripts para $CONFIG_DIR..."

for file in "${SCRIPT_FILES[@]}"; do
    src="$DOTS_DIR/$file"
    dest="$CONFIG_DIR/$file"

    if [[ ! -e "$src" ]]; then
        echo "  !! $file não existe em $DOTS_DIR, pulando"
        continue
    fi

    echo "  -> $file"
    cp -a "$src" "$dest"
done

echo "==> Concluído."
