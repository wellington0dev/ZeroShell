#!/usr/bin/env bash
#
# Instala as dependências usadas por este setup Hyprland + quickshell,
# copia as configs de ~/ZeroShell pra ~/.config (CONFIG_DIRS) e os
# scripts do setup pra lá também (SCRIPT_FILES), com base nos arrays
# em dirs.sh. Cópia de verdade, não symlink.
#
# Também instala o yay caso ele ainda não esteja disponível e usa o
# yay para instalar os pacotes definidos em YAY_PKGS.
#
# Usage:
#   ./install.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/dirs.sh"

PACMAN_PKGS=(
    sddm
    hyprland
    quickshell
    awww
    matugen
    python-pillow
    kitty
    dolphin
    playerctl
    wireplumber
    brightnessctl
    libnotify
    grim
    cava
    ttf-jetbrains-mono-nerd
    python-pam
    bluetui
    btop
    fastfetch
    starship
)

YAY_PKGS=(
    wlctl
)


# ---------------------------------------------------------------------------
# Pacotes oficiais
# ---------------------------------------------------------------------------

echo "==> Instalando pacotes oficiais..."

sudo pacman -S --needed "${PACMAN_PKGS[@]}"


# ---------------------------------------------------------------------------
# Instalação do yay
# ---------------------------------------------------------------------------

if command -v yay >/dev/null 2>&1; then
    echo "==> yay já está instalado."
else
    echo "==> yay não encontrado. Instalando..."

    if [[ "${EUID}" -eq 0 ]]; then
        echo "!! Não execute este script como root para instalar o yay."
        echo "   Execute como usuário normal."
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "==> git não encontrado. Instalando..."
        sudo pacman -S --needed git
    fi

    if ! command -v base-devel >/dev/null 2>&1; then
        echo "==> Instalando ferramentas de compilação..."
        sudo pacman -S --needed base-devel
    else
        echo "==> base-devel já disponível."
    fi

    yay_build_dir="$(mktemp -d)"

    trap 'rm -rf "$yay_build_dir"' EXIT

    echo "==> Clonando yay..."

    git clone \
        https://aur.archlinux.org/yay.git \
        "$yay_build_dir/yay"

    cd "$yay_build_dir/yay"

    echo "==> Compilando e instalando yay..."

    makepkg -si --noconfirm

    cd - >/dev/null

    echo "==> yay instalado."
fi


# ---------------------------------------------------------------------------
# Pacotes AUR
# ---------------------------------------------------------------------------

if ((${#YAY_PKGS[@]} > 0)); then
    echo "==> Instalando pacotes do AUR..."

    yay -S --needed "${YAY_PKGS[@]}"
fi


# ---------------------------------------------------------------------------
# Configurações
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------

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