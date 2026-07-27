pragma Singleton

import QtQuick
import Quickshell

// Estado compartilhado entre DashboardTrigger.qml (a faixa sensível de 10px
// no topo da tela) e DashboardWindow.qml (o card que desce). São duas
// PanelWindow separadas - não dá pra uma referenciar a outra diretamente -,
// então esse singleton é o ponto de encontro dos dois: cada uma diz aqui se
// o mouse tá em cima dela, e "open" combina os dois sinais.
Singleton {
    id: root

    property bool hoveringTrigger: false
    property bool hoveringCard: false

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
}
