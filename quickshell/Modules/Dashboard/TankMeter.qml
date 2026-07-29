import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Theme
import qs.Widgets

// Card "tanque": em vez de um anel, a própria cor de fundo sobe feito
// líquido conforme a porcentagem - inspirado no BatteryTank.qml do
// caelestia (github.com/caelestia-dots/shell). Estreito e alto, pensado
// pra bateria dentro do grid bento da aba Sistema.
//
// "ClippingRectangle" em vez de Rectangle+clip:true: um Rectangle comum só
// recorta os filhos numa caixa reta (ignora o "radius" pra esse fim), então
// o líquido com cantos retos vazava pra fora dos cantos arredondados do
// card. ClippingRectangle recorta de verdade seguindo o formato arredondado.
ClippingRectangle {
    id: root

    property string icon
    property string label
    property int percent: 0
    property color fillColor: Colors.accent

    radius: Colors.radiusShell
    color: Colors.surface
    border.color: Colors.border
    border.width: 1

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * Math.max(0, Math.min(1, root.percent / 100))
        color: Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.3)

        Behavior on height {
            NumberAnimation { duration: Motion.durationSlow; easing.type: Easing.OutCubic }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Icon {
            Layout.alignment: Qt.AlignHCenter
            icon: root.icon
            size: 20
            tint: root.fillColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.percent + "%"
            color: Colors.foreground
            font.pixelSize: 17
            font.family: Colors.fontFamily
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            color: Colors.foregroundMuted
            font.pixelSize: 10
            font.family: Colors.fontFamily
        }
    }
}
