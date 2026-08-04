#!/usr/bin/env bash
#
# Igual ao test-styles.sh (mesmos cliques de verdade, mesmas coordenadas
# calibradas), mas grava um vídeo contínuo (wf-recorder) passando por cada
# combinação em vez de tirar um print de cada uma - dá pra ver a TRANSIÇÃO
# entre temas (a animação da troca de cor, não só o antes/depois), coisa que
# uma sequência de prints não mostra. Salvo em
# ~/Videos/test-styles/<data-hora>.mp4. Chamado pela aba "Testes" das
# Configurações, ou direto pelo terminal.
#
# Usage:
#   test-styles-video.sh

set -euo pipefail

MODE_FILE="$HOME/.config/quickshell/State/theme-mode.json"
COLORS_FILE="$HOME/.config/quickshell/State/colors.json"
OUT_DIR="$HOME/Videos/test-styles"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"

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

RECORDER_PID=""
restore_theme() {
    echo "==> Devolvendo o tema original..."
    printf '%s' "$BACKUP_MODE" > "$MODE_FILE"
    printf '%s' "$BACKUP_COLORS" > "$COLORS_FILE"
    # Se o script saiu no meio (erro, Ctrl+C) o wf-recorder ainda pode estar
    # rodando - mata ele aqui pra não sobrar processo nem arquivo .mp4
    # corrompido/incompleto sem ninguém saber.
    if [ -n "$RECORDER_PID" ] && kill -0 "$RECORDER_PID" 2>/dev/null; then
        kill -INT "$RECORDER_PID"
        wait "$RECORDER_PID" 2>/dev/null || true
    fi
    qs ipc call settings close >/dev/null 2>&1 || true
    hyprctl dispatch "hl.dsp.focus({workspace = $ORIGINAL_WORKSPACE})" >/dev/null 2>&1 || true
}
trap restore_theme EXIT

# Fecha ANTES de trocar de workspace - ver comentário igual em
# test-styles.sh (se Configurações já estiver aberta - ex.: rodando pelo
# botão "play" da própria aba Testes - ela fica pra trás no workspace de
# origem quando o foco muda, não "segue" sozinha; todo clique depois disso
# mira uma janela fora de tela). Mesmo padrão do debug-shell-video.sh
# ("Fechando tudo antes de começar").
qs ipc call settings close >/dev/null 2>&1 || true
sleep 0.3

# Mesmo truque do debug-shell-video.sh: workspace vazio dedicado, só pra dar
# um fundo limpo no vídeo (sem janelas de verdade atrás do painel de
# Configurações).
DEBUG_WORKSPACE=99
ORIGINAL_WORKSPACE="$(hyprctl activeworkspace -j | jq -r '.id')"
hyprctl dispatch "hl.dsp.focus({workspace = $DEBUG_WORKSPACE})" >/dev/null
sleep 0.3

# Devolve "x y" da janela de Configurações (canto superior esquerdo, em
# pixel de tela - mesmo espaço do grim/hyprctl, NÃO do ydotool ainda).
# Consultado de novo a cada clique (não guardado numa variável só no
# início) - ver test-styles.sh pra o porquê (a janela realmente muda de
# lugar entre um clique e outro às vezes).
window_pos() {
    hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if 'onfigura' in c.get('title', ''):
        print(c['at'][0], c['at'][1])
        break
"
}

# click_rel <dx> <dy>: mesma lógica de test-styles.sh (confere a posição de
# novo depois do mousemove, antes de clicar - retry se a janela se mexeu no
# meio do caminho).
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

# "Cores do wallpaper" precisa estar ligado antes da varredura - ver
# comentário igual em test-styles.sh.
python3 -c "
import json
d = json.load(open('$MODE_FILE'))
d['useWallpaperColors'] = True
json.dump(d, open('$MODE_FILE', 'w'), indent=4)
"
sleep 0.3

# "-D" desliga a otimização de só gravar frame quando a tela muda - com ela,
# um trecho parado (sem animação rodando) vira framerate variável/quase
# parado no vídeo final. Sem áudio (só interessa o visual aqui). Mesmas
# flags do debug-shell-video.sh.
echo "==> Iniciando gravação..."
wf-recorder -D -f "$OUT_FILE" >/dev/null 2>&1 &
RECORDER_PID=$!
sleep 0.5  # dá tempo do wf-recorder abrir o arquivo antes do 1o clique

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
# vivo em ~1.5s. Um HOLD_TIME menor que isso faz o PRÓXIMO clique disparar
# antes da troca de cor anterior terminar de aplicar (mesmo bug do
# test-styles.sh, só que aqui vira uma transição "atropelada" no vídeo em
# vez de um print errado).
HOLD_TIME=2.0  # tempo que cada combinação fica em tela, gravando

echo "==> Varrendo estilo de cor x claro/escuro (${#SCHEME_ORDER[@]} x ${#MODE_ORDER[@]} = $(( ${#SCHEME_ORDER[@]} * ${#MODE_ORDER[@]} )) combinações, clicando de verdade)..."
for mode in "${MODE_ORDER[@]}"; do
    read -r mx my <<< "${MODE_POS[$mode]}"
    click_rel "$mx" "$my"
    sleep "$HOLD_TIME"

    for scheme in "${SCHEME_ORDER[@]}"; do
        read -r sx sy <<< "${SCHEME_POS[$scheme]}"
        click_rel "$sx" "$sy"
        sleep "$HOLD_TIME"
        echo "  -> $mode-$scheme"
    done
done

click_rel 302 113  # aba "Personalizar"
sleep "$HOLD_TIME"

PRESET_ORDER=(tokyo-night catppuccin-mocha catppuccin-macchiato catppuccin-frappe catppuccin-latte nord gruvbox-dark)
declare -A PRESET_POS=(
    [tokyo-night]="144 228" [catppuccin-mocha]="272 228" [catppuccin-macchiato]="400 228" [catppuccin-frappe]="528 228"
    [catppuccin-latte]="144 300" [nord]="272 300" [gruvbox-dark]="400 300"
)

echo "==> Varrendo temas prontos (${#PRESET_ORDER[@]}, clicando de verdade)..."
for name in "${PRESET_ORDER[@]}"; do
    read -r px py <<< "${PRESET_POS[$name]}"
    click_rel "$px" "$py"
    sleep "$HOLD_TIME"
    echo "  -> preset-$name"
done

echo "==> Parando gravação..."
kill -INT "$RECORDER_PID"
wait "$RECORDER_PID" 2>/dev/null || true
RECORDER_PID=""

echo
echo "✓ vídeo salvo em $OUT_FILE"
