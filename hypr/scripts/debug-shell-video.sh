#!/usr/bin/env bash
#
# Igual ao debug-shell.sh, mas grava um vídeo em vez de tirar prints: vai pro
# mesmo workspace vazio e abre cada janela/widget do quickshell por ~2s,
# tudo numa única gravação contínua (wf-recorder), salva em
# ~/Videos/debug-shell/<data-hora>.mp4. Chamado pelo botão de debug (ícone de
# vídeo) na aba "Sistema" do Dashboard, ou direto pelo terminal.
#
# Usage:
#   debug-shell-video.sh

set -euo pipefail

OUT_DIR="$HOME/Videos/debug-shell"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Mesmo workspace dedicado do debug-shell.sh (número alto, improvável de
# colidir com o uso normal) - só existe pra dar um fundo limpo no vídeo, sem
# janelas de verdade atrás dos painéis. Este Hyprland interpreta dispatch
# como Lua (ver hyprland.lua), não a sintaxe padrão "workspace N".
DEBUG_WORKSPACE=99

# "sidebar" não tem toggle (é sempre visível) - string vazia = pula abrir/
# fechar pra ele, só entra na lista de nomes pra aparecer no vídeo com o
# shell "vazio" durante os ~2s dele.
declare -A PANELS=(
    [sidebar]=""
    [launcher]="launcher"
    [settings]="settings"
    [powermenu]="powermenu"
    [capture]="capture"
    [dashboard]="dashboard"
)
# Ordem determinística (arrays associativos no bash não garantem ordem de
# iteração).
ORDER=(sidebar launcher settings powermenu capture dashboard)

# Sub-páginas de "dashboard" e "settings" - em vez de segurar só na
# aba/categoria em que o painel abre por padrão, passa por cada uma. Nomes
# batem com DashboardTabs.qml (DashboardState.currentTab) e CategoryNav.qml
# (Visibility.settingsCategory).
DASHBOARD_TABS=(home player system)
SETTINGS_CATEGORIES=(wifi bluetooth audio theme capture sidebar)

HOLD_TIME=1.5   # tempo que cada painel/página fica em tela, gravando
CLOSE_WAIT=0.3  # respiro entre fechar um painel e abrir o próximo

open_panel() {
    local target="$1"
    # "if" em vez de "[ -n ... ] &&" de propósito: com set -e, uma função
    # cujo ÚLTIMO comando é um "&&" que não dispara o lado direito devolve o
    # exit code do teste (1) - e isso derruba o script inteiro (aconteceu de
    # verdade com o "sidebar", que não tem target). "if" sempre sai 0 quando
    # a condição é falsa e não há "else".
    if [ -n "$target" ]; then
        qs ipc call "$target" open >/dev/null 2>&1
    fi
}

close_panel() {
    local target="$1"
    if [ -n "$target" ]; then
        qs ipc call "$target" close >/dev/null 2>&1
    fi
}

echo "==> Fechando tudo antes de começar (estado limpo)..."
for name in "${ORDER[@]}"; do
    close_panel "${PANELS[$name]}"
done
sleep "$CLOSE_WAIT"

ORIGINAL_WORKSPACE="$(hyprctl activeworkspace -j | jq -r '.id')"

echo "==> Indo pro workspace $DEBUG_WORKSPACE (vazio)..."
hyprctl dispatch "hl.dsp.focus({workspace = $DEBUG_WORKSPACE})" >/dev/null
sleep 0.3

# "-D" desliga a otimização de só gravar frame quando a tela muda - com ela,
# um painel parado em tela (sem animação rodando) vira um trecho com
# framerate variável/quase parado no vídeo final, o que fica com uma
# sensação de "engasgo" na troca pro próximo painel. Sem áudio (só interessa
# o visual aqui).
echo "==> Iniciando gravação..."
wf-recorder -D -f "$OUT_FILE" >/dev/null 2>&1 &
RECORDER_PID=$!
sleep 0.5  # dá tempo do wf-recorder abrir o arquivo antes do 1o painel

echo "==> Passando por cada painel (~${HOLD_TIME}s cada)..."
for name in "${ORDER[@]}"; do
    target="${PANELS[$name]}"
    open_panel "$target"
    sleep "$HOLD_TIME"

    # "dashboard" e "settings" têm sub-páginas próprias (abas/categorias) -
    # em vez de segurar só na página padrão, passa por cada uma antes de
    # fechar o painel.
    if [ "$name" = "dashboard" ]; then
        for tab in "${DASHBOARD_TABS[@]}"; do
            qs ipc call dashboard tab "$tab" >/dev/null 2>&1
            sleep "$HOLD_TIME"
        done
    elif [ "$name" = "settings" ]; then
        for cat in "${SETTINGS_CATEGORIES[@]}"; do
            qs ipc call settings category "$cat" >/dev/null 2>&1
            sleep "$HOLD_TIME"
        done
    fi

    echo "  -> $name"
    close_panel "$target"
    sleep "$CLOSE_WAIT"
done

# Lockscreen fica de fora do PANELS/ORDER de propósito: não usa IPC "open"/
# "close" como os outros (só "lock", e o IpcHandler nunca expõe um "unlock"
# de verdade - só a senha certa destrava, ver Modules/Lock/LockScreen.qml).
# "debugUnlock" é a única forma de fechar sem digitar senha, e é uma função
# DEBUG TEMPORÁRIA - se for removida no futuro, este passo aqui também
# precisa sair (ou passar a exigir senha real pra continuar).
echo "==> Passando pelo lockscreen (~${HOLD_TIME}s)..."
qs ipc call lockscreen lock >/dev/null 2>&1
sleep "$HOLD_TIME"
qs ipc call lockscreen debugUnlock >/dev/null 2>&1
sleep "$CLOSE_WAIT"

echo "==> Todos juntos (~${HOLD_TIME}s)..."
for name in "${ORDER[@]}"; do
    open_panel "${PANELS[$name]}"
done
sleep "$HOLD_TIME"

echo "==> Fechando tudo de novo..."
for name in "${ORDER[@]}"; do
    close_panel "${PANELS[$name]}"
done
sleep "$CLOSE_WAIT"

echo "==> Parando gravação..."
kill -INT "$RECORDER_PID"
wait "$RECORDER_PID" 2>/dev/null || true

echo "==> Voltando pro workspace $ORIGINAL_WORKSPACE..."
hyprctl dispatch "hl.dsp.focus({workspace = $ORIGINAL_WORKSPACE})" >/dev/null

echo
echo "✓ vídeo salvo em $OUT_FILE"
