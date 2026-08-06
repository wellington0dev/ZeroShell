#!/usr/bin/env bash
#
# Auditoria visual do shell: vai pra um workspace vazio, tira print de cada
# janela/widget do quickshell individualmente e depois de todos juntos, e
# guarda tudo em ~/Pictures/debug-shell/<data-hora>/. Útil pra conferir o
# visual depois de mexer em tema/cores/raio sem precisar abrir cada painel
# na mão. Chamado pelo botão de debug na aba "Sistema" do Dashboard, ou
# direto pelo terminal.
#
# Usage:
#   debug-shell.sh

set -euo pipefail

OUT_DIR="$HOME/Pictures/debug-shell/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$OUT_DIR"

# Workspace dedicado (número alto, improvável de colidir com o uso normal) -
# só existe pra dar um fundo limpo nos prints, sem janelas de verdade atrás
# dos painéis. Este Hyprland interpreta dispatch como Lua (ver hyprland.lua),
# não a sintaxe padrão "workspace N".
DEBUG_WORKSPACE=99

# "sidebar" não tem toggle (é sempre visível) - string vazia = pula abrir/
# fechar pra ele, só entra na lista de nomes pra aparecer no print "todos
# juntos" e ter seu próprio print individual (o shell "vazio").
declare -A PANELS=(
    [sidebar]=""
    [launcher]="launcher"
    [settings]="settings"
    [powermenu]="powermenu"
    [volume]="volume"
    [capture]="capture"
    [dashboard]="dashboard"
)
# Ordem determinística de captura (arrays associativos no bash não garantem
# ordem de iteração).
ORDER=(sidebar launcher settings powermenu volume capture dashboard)

# Sub-páginas de "dashboard" e "settings" - cada uma ganha o próprio print
# (dashboard-home.png, settings-wifi.png, etc.) em vez de só a aba/categoria
# em que o painel abriu por padrão. Nomes batem com DashboardTabs.qml
# (DashboardState.currentTab) e CategoryNav.qml (Visibility.settingsCategory).
DASHBOARD_TABS=(home player system quick)
SETTINGS_CATEGORIES=(wifi bluetooth audio theme capture sidebar plugins dock keybinds)

OPEN_WAIT=0.6   # tempo pra animação de abrir terminar antes do print
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

echo "==> Capturando cada painel individualmente..."
for name in "${ORDER[@]}"; do
    target="${PANELS[$name]}"
    open_panel "$target"
    sleep "$OPEN_WAIT"

    # "dashboard" e "settings" têm sub-páginas próprias (abas/categorias) -
    # em vez de um print só (sempre a página padrão), passa por cada uma.
    if [ "$name" = "dashboard" ]; then
        for tab in "${DASHBOARD_TABS[@]}"; do
            qs ipc call dashboard tab "$tab" >/dev/null 2>&1
            sleep "$OPEN_WAIT"
            grim "$OUT_DIR/dashboard-$tab.png"
            echo "  -> dashboard-$tab.png"
        done
    elif [ "$name" = "settings" ]; then
        for cat in "${SETTINGS_CATEGORIES[@]}"; do
            qs ipc call settings category "$cat" >/dev/null 2>&1
            sleep "$OPEN_WAIT"
            grim "$OUT_DIR/settings-$cat.png"
            echo "  -> settings-$cat.png"
        done
    else
        grim "$OUT_DIR/$name.png"
        echo "  -> $name.png"
    fi

    close_panel "$target"
    sleep "$CLOSE_WAIT"
done

# Lockscreen fica de fora do PANELS/ORDER de propósito: não usa IPC "open"/
# "close" como os outros (só "lock", e o IpcHandler nunca expõe um "unlock"
# de verdade - só a senha certa destrava, ver Modules/Lock/LockScreen.qml).
# "debugUnlock" é a única forma de fechar sem digitar senha, e é uma função
# DEBUG TEMPORÁRIA - se for removida no futuro, este passo aqui também
# precisa sair (ou passar a exigir senha real pra continuar). Também fica de
# fora do "all-together": é uma superfície de sessão travada de verdade,
# cobre a tela toda por cima de tudo - combinar com os outros painéis não
# mostraria nada além dela mesma.
echo "==> Capturando lockscreen..."
qs ipc call lockscreen lock >/dev/null 2>&1
sleep "$OPEN_WAIT"
grim "$OUT_DIR/lockscreen.png"
echo "  -> lockscreen.png"
qs ipc call lockscreen debugUnlock >/dev/null 2>&1
sleep "$CLOSE_WAIT"

echo "==> Abrindo tudo junto..."
# Volta dashboard/settings pra sub-página padrão antes do print combinado -
# sem isso ficariam parados na última aba/categoria do loop acima (ex.:
# "settings-sidebar"), em vez do estado inicial normal do shell.
qs ipc call dashboard tab home >/dev/null 2>&1
qs ipc call settings category theme >/dev/null 2>&1
for name in "${ORDER[@]}"; do
    open_panel "${PANELS[$name]}"
done
sleep "$OPEN_WAIT"
grim "$OUT_DIR/all-together.png"
echo "  -> all-together.png"

echo "==> Fechando tudo de novo..."
for name in "${ORDER[@]}"; do
    close_panel "${PANELS[$name]}"
done

echo "==> Voltando pro workspace $ORIGINAL_WORKSPACE..."
hyprctl dispatch "hl.dsp.focus({workspace = $ORIGINAL_WORKSPACE})" >/dev/null

echo
echo "✓ prints salvos em $OUT_DIR"
