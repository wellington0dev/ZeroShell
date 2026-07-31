pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado compartilhado entre VolumeTrigger.qml (a faixa sensível colada na
// borda direita) e VolumePanel.qml (o card que desliza) - mesma técnica do
// DashboardState.qml: duas PanelWindow separadas não enxergam uma à outra
// direto, então esse singleton é o ponto de encontro. Cada uma diz aqui se o
// mouse tá em cima dela, e "open" combina os dois sinais.
Singleton {
    id: root

    property bool hoveringTrigger: false
    property bool hoveringPanel: false

    // Só fecha depois de um tempinho sem estar em cima de nenhum dos dois -
    // evita fechar e reabrir na hora (flicker) bem no instante em que o
    // mouse sai da faixa sensível e ainda não "chegou" no painel, já que o
    // painel desliza por trás dela.
    readonly property bool wantsOpen: hoveringTrigger || hoveringPanel
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

    // Abre/fecha programaticamente, pra scripts (ex.: debug-shell.sh) sem
    // precisar simular o mouse em cima da faixa sensível - mesmo raciocínio
    // do IpcHandler em DashboardState.qml.
    IpcHandler {
        target: "volume"

        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }
}
