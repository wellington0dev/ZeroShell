import QtQuick
import Quickshell

// Faixa invisível de 10px colada no topo da tela, sempre presente. Só existe
// pra detectar quando o mouse passa por ali - ao contrário do
// DashboardWindow (que fica fora da tela quando fechado), essa aqui nunca se
// move, então precisa ser bem fina pra não atrapalhar cliques em outras
// janelas encostadas no topo.
//
// A PanelWindow em si continua esticada de ponta a ponta (uma PanelWindow
// ancorada só no "top", sem "left"/"right", NÃO fica centralizada sozinha -
// testado ao vivo via "hyprctl layers", a superfície continuava com a
// largura da tela inteira). Por isso só a área sensível de verdade é o Item
// central de largura DashboardState.cardWidth - mesmo truque do card
// centralizado dentro da janela cheia do DashboardWindow.qml.
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 10

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: DashboardState.cardWidth
        height: parent.height

        HoverHandler {
            onHoveredChanged: DashboardState.hoveringTrigger = hovered
        }
    }
}
