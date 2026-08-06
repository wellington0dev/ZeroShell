pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado compartilhado entre DashboardTrigger.qml (a faixa sensível de 10px
// no topo da tela) e DashboardWindow.qml (o card que desce). São duas
// PanelWindow separadas - não dá pra uma referenciar a outra diretamente -,
// então esse singleton é o ponto de encontro dos dois: cada uma diz aqui se
// o mouse tá em cima dela, e "open" combina os dois sinais.
Singleton {
    id: root

    // Largura do card (DashboardWindow.qml) - também usada pela faixa de
    // ativação (DashboardTrigger.qml) pra ficar do mesmo tamanho dele, em vez
    // da largura inteira da tela.
    readonly property int cardWidth: 560

    property bool hoveringTrigger: false
    property bool hoveringCard: false

    // Aba ativa (DashboardTabs.qml) - mora aqui, não como property local da
    // aba, pra dar pra trocar de fora via IPC (hypr/scripts/debug-shell.sh e
    // debug-shell-video.sh), sem precisar simular clique na aba.
    property string currentTab: "home"

    // Só fecha depois de um tempinho sem estar em cima de nenhum dos dois -
    // evita fechar e reabrir na hora (flicker) bem no instante em que o
    // mouse sai da faixa sensível e ainda não "chegou" no card, já que o
    // card desliza por baixo dela.
    readonly property bool wantsOpen: hoveringTrigger || hoveringCard
    property bool open: false

    onWantsOpenChanged: {
        if (wantsOpen) {
            closeTimer.stop()
            root.open = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.open = false
    }

    // O Dashboard normalmente só abre por hover (sem keybind, sem clique) -
    // isso dá um jeito de abrir/fechar programaticamente, pra scripts (ex.:
    // hypr/scripts/debug-shell.sh) sem precisar simular o mouse em cima da
    // faixa sensível. Setar "open" direto aqui é seguro: só é sobrescrito
    // por onWantsOpenChanged acima quando o hover de verdade mudar.
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.open = !root.open
        }
        // Nomeadas igual às outras janelas (open/close, além do toggle) por
        // consistência - "root.open =" aqui aponta pra property acima, sem
        // ambiguidade (função e property vivem em objetos diferentes).
        function open(): void { root.open = true }
        function close(): void { root.open = false }

        // Troca a aba ativa - "home", "player", "system" ou "quick" (ver
        // Modules/Dashboard/DashboardTabs.qml). Não valida o nome: um valor
        // inválido só faz o Loader do DashboardWindow.qml cair no "default"
        // (aba "home"), sem quebrar nada.
        function tab(name: string): void { root.currentTab = name }
    }
}
