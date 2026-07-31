# Lista de diretórios de configuração gerenciados pelo dotfiles.
# Usado tanto por update.sh (config -> dotfiles) quanto por install.sh (dotfiles -> config).

CONFIG_DIRS=(
    hypr
    quickshell
    kitty
    matugen
)

# Scripts do próprio setup (ficam na raiz de ~/.config e de ~/dotfiles).
SCRIPT_FILES=(
    install.sh
    update.sh
    dirs.sh
    README.md
)

CONFIG_DIR="$HOME/.config"
DOTS_DIR="$HOME/ZeroShell"
