#!/usr/bin/env bash

# Caminho para o arquivo de cores do Quickshell/Matugen
COLORS_FILE="$HOME/.config/quickshell/State/colors.json"

# Verifica se o arquivo de cores existe
if [ ! -f "$COLORS_FILE" ]; then
    echo "Erro: Arquivo de cores não encontrado em $COLORS_FILE" >&2
    # Fallback para cores estáticas se o arquivo não existir
    export ROFI_BG="#1a1a1a"
    export ROFI_FG="#ffffff"
    export ROFI_BG_ALT="#2a2a2a"
    export ROFI_BORDER="#42493baa"
    export ROFI_ACCENT_1="#b3ee8aee"
    export ROFI_ACCENT_2="#b9dcdfee"
else
    # Extrai e formata as cores
    ROFI_BG="#$(jq -r '.background' "$COLORS_FILE" | sed 's/#//')"
    ROFI_FG="#$(jq -r '.foreground' "$COLORS_FILE" | sed 's/#//')"
    ROFI_ACCENT_1="#$(jq -r '.accent' "$COLORS_FILE" | sed 's/#//' | sed 's/$/ee/g')" # Adiciona transparência 'ee'
    ROFI_ACCENT_2="#$(jq -r '.accentAlt' "$COLORS_FILE" | sed 's/#//' | sed 's/$/ee/g')" # Adiciona transparência 'ee'
    ROFI_BORDER="#$(jq -r '.border' "$COLORS_FILE" | sed 's/#//' | sed 's/$/aa/g')" # Adiciona transparência 'aa'
    
    # Para background-alt, vamos escurecer um pouco o background principal
    # Se o background for 1a1a1a, o alt pode ser 2a2a2a. Vamos manter a lógica de pegar do colors.json
    # e se precisar escurecer, faremos de outra forma.
    ROFI_BG_ALT="#$(jq -r '.background' "$COLORS_FILE" | sed 's/#//')"

    export ROFI_BG
    export ROFI_FG
    export ROFI_BG_ALT
    export ROFI_BORDER
    export ROFI_ACCENT_1
    export ROFI_ACCENT_2
fi

# Mata qualquer instância existente do Rofi e lança uma nova com o tema
killall rofi || rofi -show drun -theme "$HOME/.config/rofi/themes/custom-dynamic.rasi"
