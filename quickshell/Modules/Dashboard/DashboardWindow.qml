import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Theme
import qs.Widgets

// O card do dashboard em si: fica fora da tela (acima do topo) até
// DashboardState.open virar true (por causa da DashboardTrigger.qml ou por
// hover no próprio card), aí desliza pra baixo. Mesma técnica de
// "margins.top negativo pra esconder" usada em Helena/Player, só que
// centralizado na tela em vez de alinhado à sidebar.
//
// 3 abas (DashboardTabs.qml): Início (relógio + foto + notificações),
// Player (PlayerContent, movido pra cá em vez de ter janela própria) e
// Sistema (CPU/RAM/bateria).
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: card.height + 20

    margins.top: DashboardState.open ? 0 : - implicitHeight

    Behavior on margins.top {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    Shadow { target: card }

    // Largura igual nas 3 abas - só a altura muda conforme o conteúdo.
    readonly property int cardWidth: 560
    readonly property var tabHeights: ({
        home: 420,
        player: 260,
        system: 320
    })
    readonly property var currentSize: ({ w: cardWidth, h: tabHeights[tabs.current] || tabHeights.home })

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        width: root.currentSize.w
        height: root.currentSize.h
        radius: Colors.radiusLarge
        color: Colors.background
        border.color: Colors.border
        border.width: 2

        Behavior on width {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }

        HoverHandler {
            onHoveredChanged: DashboardState.hoveringCard = hovered
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacing * 2
            spacing: Colors.spacing * 1.5

            DashboardTabs {
                id: tabs
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.border
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: DashboardState.open
                sourceComponent: {
                    switch (tabs.current) {
                        case "player": return playerTabComp
                        case "system": return systemTabComp
                        default: return homeTabComp
                    }
                }
            }
        }
    }

    Component { id: homeTabComp; HomeTab {} }
    Component { id: playerTabComp; PlayerTab {} }
    Component { id: systemTabComp; SystemTab {} }
}
