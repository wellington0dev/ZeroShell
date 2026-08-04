#!/usr/bin/env bash
#
# Varredura automática de todas as combinações de "Estilo de cor" (--type do
# matugen) x "Claro/escuro" (--mode), mais os temas prontos (Catppuccin,
# Nord, etc), CLICANDO de verdade nos botões de Configurações > Aparência
# (ydotool) - não escrevendo os arquivos de estado direto. Testa o caminho
# real (TapHandler -> Styles.setSchemeType/setColorMode/setCustom ->
# apply-theme.sh), não só "o visual bate com um estado dado". Guarda um
# print de cada combinação em ~/Pictures/test-styles/<data-hora>/ e devolve
# o theme-mode.json/colors.json originais no final (via trap - mesmo se o
# script for interrompido no meio). Chamado pela aba "Testes" das
# Configurações, ou direto pelo terminal.
#
# Coordenadas calibradas contra o layout de WallpaperGrid.qml/
# ColorCustomizer.qml/CategoryNav.qml - relativas ao canto superior esquerdo
# da janela de Configurações (720x480, ver SettingsWindow.qml), não
# absolutas: a posição da janela na tela é lida de novo (hyprctl) antes de
# CADA clique, então funciona não importa onde a janela esteja. As
# coordenadas do ydotool são a metade das da tela (compositor roda em
# escala 2x nesta máquina - confirmado ao vivo comparando grim x hyprctl).
# Se o texto de algum botão mudar, as coordenadas aqui provavelmente
# quebram e precisam ser recalibradas (print + medir, não advinhar).
#
# Usage:
#   test-styles.sh

set -euo pipefail

MODE_FILE="$HOME/.config/quickshell/State/theme-mode.json"
COLORS_FILE="$HOME/.config/quickshell/State/colors.json"
OUT_DIR="$HOME/Pictures/test-styles/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$OUT_DIR"

WALLPAPER="$(cat "$HOME/.cache/hypr/wallpaper_current" 2>/dev/null || true)"
if [ -z "$WALLPAPER" ]; then
    echo "Nenhum wallpaper ativo (~/.cache/hypr/wallpaper_current vazio), abortando." >&2
    exit 1
fi

# Este script SOBRESCREVE theme-mode.json/colors.json repetidamente durante
# a varredura - guarda o conteúdo de verdade agora pra devolver no final,
# aconteça o que acontecer (trap EXIT cobre erro, Ctrl+C, término normal).
BACKUP_MODE="$(cat "$MODE_FILE" 2>/dev/null || echo '{}')"
BACKUP_COLORS="$(cat "$COLORS_FILE" 2>/dev/null || echo '{}')"

restore_theme() {
    echo "==> Devolvendo o tema original..."
    printf '%s' "$BACKUP_MODE" > "$MODE_FILE"
    printf '%s' "$BACKUP_COLORS" > "$COLORS_FILE"
    qs ipc call settings close >/dev/null 2>&1 || true
    hyprctl dispatch "hl.dsp.focus({workspace = $ORIGINAL_WORKSPACE})" >/dev/null 2>&1 || true
}
trap restore_theme EXIT

# Fecha ANTES de trocar de workspace - se Configurações já estivesse aberta
# (ex.: rodando este script pelo botão "play" da própria aba Testes, dentro
# de Configurações), ela fica pra trás no workspace de origem quando o foco
# muda pro workspace de debug (testado ao vivo: hyprctl confirma a janela
# continua com workspace.id igual ao original, mesmo depois do foco mudar -
# ela não "segue" o foco sozinha). Todo clique subsequente então mira uma
# janela que não está mais em tela nenhuma - é exatamente esse o motivo do
# script "não funcionar" quando chamado de dentro das Configurações. Mesmo
# padrão do debug-shell.sh ("Fechando tudo antes de começar").
qs ipc call settings close >/dev/null 2>&1 || true
sleep 0.3

# Mesmo truque do debug-shell.sh: workspace vazio dedicado, só pra dar um
# fundo limpo nos prints (sem janelas de verdade atrás do painel de
# Configurações).
DEBUG_WORKSPACE=99
ORIGINAL_WORKSPACE="$(hyprctl activeworkspace -j | jq -r '.id')"
hyprctl dispatch "hl.dsp.focus({workspace = $DEBUG_WORKSPACE})" >/dev/null
sleep 0.3

# Devolve "x y" da janela de Configurações (canto superior esquerdo, em
# pixel de tela - mesmo espaço do grim/hyprctl, NÃO do ydotool ainda).
# Consultado de novo a cada clique (não guardado numa variável só no
# início) de propósito - várias vezes hoje a janela mudou de lugar entre
# um print e o clique seguinte, e isso é o que causava clique errado.
window_pos() {
    hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if 'onfigura' in c.get('title', ''):
        print(c['at'][0], c['at'][1])
        break
"
}

# click_rel <dx> <dy>: clica no ponto (dx,dy) relativo ao canto superior
# esquerdo da janela AGORA (window_pos fresco). Divide por 2 no final (não
# em cada termo) - escala 2x do ydotool nesta máquina.
#
# Confere a posição de NOVO depois do mousemove, antes de clicar - a janela
# pode se mover entre a consulta e o clique (visto ao vivo: mesma janela,
# duas consultas hyprctl em sequência rápida, posições diferentes - o
# Hyprland deve recalcular/centralizar ela em algum gatilho). Se mudou,
# recomeça (mousemove pro lugar novo) até 5 vezes antes de desistir - clicar
# achando que a janela ainda tá onde a primeira consulta disse é o que
# derrubava a varredura inteira em silêncio (janela fechava sozinha depois
# de um clique feito no lugar errado, e o resto dos prints saía do
# workspace vazio, sem Configurações nenhuma).
click_rel() {
    local dx="$1" dy="$2"
    local attempt wx wy x y wx2 wy2
    for attempt in 1 2 3 4 5; do
        read -r wx wy < <(window_pos)
        if [ -z "${wx:-}" ]; then
            echo "  !! janela de Configurações não encontrada, abortando" >&2
            exit 1
        fi
        x=$(( (wx + dx) / 2 ))
        y=$(( (wy + dy) / 2 ))
        ydotool mousemove --absolute -x "$x" -y "$y"
        sleep 0.12
        read -r wx2 wy2 < <(window_pos)
        if [ "$wx" = "$wx2" ] && [ "$wy" = "$wy2" ]; then
            ydotool click 0xC0
            return 0
        fi
        # Moveu entre a consulta e agora - tenta de novo com a posição nova.
    done
    echo "  !! janela ficou se mexendo, clicando mesmo assim (última posição)" >&2
    ydotool click 0xC0
}

qs ipc call settings open >/dev/null 2>&1
sleep 0.4
click_rel 33 217   # ícone "Aparência" (palette) na CategoryNav
sleep 0.2
click_rel 161 113  # aba "Cores do wallpaper"
sleep 0.3

# "Cores do wallpaper" (useWallpaperColors) precisa estar ligado ANTES da
# varredura - os botões de estilo/modo abaixo não mexem nesse toggle
# sozinhos (só setSchemeType/setColorMode), e apply-theme.sh não faz nada
# se ele tiver desligado (ver hypr/scripts/apply-theme.sh). Isto é
# "arrange" (estado de partida), não faz parte do que está sendo testado -
# o teste de verdade começa nos cliques logo abaixo.
python3 -c "
import json
d = json.load(open('$MODE_FILE'))
d['useWallpaperColors'] = True
json.dump(d, open('$MODE_FILE', 'w'), indent=4)
"
sleep 0.3

# Coordenadas (x,y) relativas à janela de cada botão - medidas por
# detecção de borda num screenshot real, não estimadas visualmente (ver
# comentário grande no topo do arquivo).
declare -A SCHEME_POS=(
    [scheme-content]="122 213" [scheme-expressive]="215 213" [scheme-fidelity]="311 213"
    [scheme-fruit-salad]="411 213" [scheme-monochrome]="519 213" [scheme-neutral]="612 213"
    [scheme-rainbow]="122 251" [scheme-tonal-spot]="215 251" [scheme-vibrant]="308 251"
)
SCHEME_ORDER=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot scheme-vibrant)
declare -A MODE_POS=([dark]="118 313" [light]="190 313")
MODE_ORDER=(dark light)

# Clicar em "Estilo de cor"/"Claro ou escuro" dispara apply-theme.sh
# (matugen + sync-hypr-colors.sh) num Process em segundo plano - medido ao
# vivo em ~1.5s. Os 0.5-0.6s de antes eram curtos demais: o print saía
# sempre UM PASSO ATRASADO (ainda com a cor do clique anterior). Isso
# ficava invisível enquanto "Estilo de cor" não mudava quase nada
# visualmente (bug antigo, já corrigido) - só ficou óbvio depois que os
# estilos passaram a produzir cores de verdade diferentes uns dos outros.
APPLY_THEME_WAIT=2.0

echo "==> Varrendo estilo de cor x claro/escuro (${#SCHEME_ORDER[@]} x ${#MODE_ORDER[@]} = $(( ${#SCHEME_ORDER[@]} * ${#MODE_ORDER[@]} )) combinações, clicando de verdade)..."
for mode in "${MODE_ORDER[@]}"; do
    read -r mx my <<< "${MODE_POS[$mode]}"
    click_rel "$mx" "$my"
    sleep "$APPLY_THEME_WAIT"

    for scheme in "${SCHEME_ORDER[@]}"; do
        read -r sx sy <<< "${SCHEME_POS[$scheme]}"
        click_rel "$sx" "$sy"
        sleep "$APPLY_THEME_WAIT"
        grim "$OUT_DIR/$mode-$scheme.png"
        echo "  -> $mode-$scheme.png"
    done
done

click_rel 302 113  # aba "Personalizar"
sleep 0.4

# Posição (x,y) de cada card de tema pronto, mesma ordem/rótulos de
# Modules/Settings/ColorCustomizer.qml ("presets") - 4 colunas, 2 linhas.
PRESET_ORDER=(tokyo-night catppuccin-mocha catppuccin-macchiato catppuccin-frappe catppuccin-latte nord gruvbox-dark)
declare -A PRESET_POS=(
    [tokyo-night]="144 228" [catppuccin-mocha]="272 228" [catppuccin-macchiato]="400 228" [catppuccin-frappe]="528 228"
    [catppuccin-latte]="144 300" [nord]="272 300" [gruvbox-dark]="400 300"
)

echo "==> Varrendo temas prontos (${#PRESET_ORDER[@]}, clicando de verdade)..."
for name in "${PRESET_ORDER[@]}"; do
    read -r px py <<< "${PRESET_POS[$name]}"
    click_rel "$px" "$py"
    sleep 0.8
    grim "$OUT_DIR/preset-$name.png"
    echo "  -> preset-$name.png"
done

echo
echo "✓ prints salvos em $OUT_DIR"
