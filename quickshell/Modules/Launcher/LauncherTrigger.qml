import QtQuick
import Quickshell
import qs.State

// Faixa invisível de 10px colada no fundo da tela, sempre presente. Passar o
// mouse por ali abre o launcher (Visibility.launcherOpen = true) - só abre,
// não fecha sozinho: o launcher é uma busca por teclado, então depois que
// abre o mouse normalmente nem fica em cima do painel enquanto se digita -
// fechar ao sair do hover atrapalharia. Fechar continua do jeito de sempre:
// Esc, clique fora, lançar um app, ou SUPER+R de novo.
//
// Mesmo truque do DashboardTrigger.qml: a PanelWindow fica esticada de
// ponta a ponta (ancorada só em "bottom" ela não centraliza sozinha), só a
// área sensível de verdade é o Item central, com a mesma largura do card em
// LauncherWindow.qml (480 - sem constante compartilhada porque só estes
// dois arquivos usam esse número).
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: 10

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 480
        height: parent.height

        HoverHandler {
            onHoveredChanged: if (hovered) Visibility.launcherOpen = true
        }
    }
}
