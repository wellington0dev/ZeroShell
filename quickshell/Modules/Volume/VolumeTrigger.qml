import QtQuick
import Quickshell

// Faixa invisível de 10px colada na borda DIREITA da tela, sempre presente -
// só existe pra detectar quando o mouse passa por ali. Mesmo truque do
// DashboardTrigger.qml/LauncherTrigger.qml: a PanelWindow fica esticada de
// ponta a ponta (ancorada em "top"+"bottom"+"right", sem "left", não
// centraliza sozinha), então só a área sensível de verdade é o Item
// central - aqui centralizado VERTICALMENTE (não horizontalmente como os
// outros dois, já que esta faixa é vertical, colada na lateral) com uma
// altura fixa, não a tela inteira, pra não vazar sensibilidade pro resto da
// borda direita (atrapalharia clique em janela maximizada ali, por exemplo).
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 10

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 160

        HoverHandler {
            onHoveredChanged: VolumeState.hoveringTrigger = hovered
        }
    }
}
