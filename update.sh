#!/usr/bin/env bash
#
# Copia as configs e os scripts de ~/.config para o repositório de dotfiles,
# com base nos arrays CONFIG_DIRS e SCRIPT_FILES (dirs.sh).
#
# Usage:
#   ./update.sh

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/dirs.sh"

mkdir -p "$DOTS_DIR"

echo "==> Copiando configs para $DOTS_DIR..."

for dir in "${CONFIG_DIRS[@]}"; do
    src="$CONFIG_DIR/$dir"
    dest="$DOTS_DIR/$dir"

    if [[ ! -e "$src" ]]; then
        echo "  !! $dir não existe em $CONFIG_DIR, pulando"
        continue
    fi

    if [[ "$(readlink -f "$src")" == "$(readlink -f "$dest")" ]]; then
        echo "  -- $dir já é um symlink pro dotfiles, nada a fazer"
        continue
    fi

    echo "  -> $dir"
    rm -rf "$dest"
    cp -a "$src" "$dest"
done

echo "==> Copiando scripts para $DOTS_DIR..."

for file in "${SCRIPT_FILES[@]}"; do
    src="$CONFIG_DIR/$file"
    dest="$DOTS_DIR/$file"

    if [[ ! -e "$src" ]]; then
        echo "  !! $file não existe em $CONFIG_DIR, pulando"
        continue
    fi

    echo "  -> $file"
    cp -a "$src" "$dest"
done

echo "==> Concluído."
