import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Um "tile" selecionável (ícone + rótulo) - usado no CaptureMenu pra escolher
// entre Região/Janela/Tela cheia. Parecido com Power/PowerButton.qml, mas
// mais simples: aqui é só uma seleção (fica destacado enquanto escolhido),
// sem a etapa de confirmação que o menu de energia tem pras ações
// destrutivas.
ColumnLayout {
    id: root

    property string icon
    property string label
    property bool selected: false

    signal activated()

    spacing: 6

    Rectangle {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56
        Layout.alignment: Qt.AlignHCenter
        radius: Colors.radiusButton
        color: root.selected
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
            : (hover.hovered ? Colors.surfaceAlt : Colors.surface)
        border.color: root.selected ? Colors.accent : Colors.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Motion.durationFast } }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 22
            tint: root.selected ? Colors.accent : Colors.foreground
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: root.activated() }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: root.selected ? Colors.accent : Colors.foregroundMuted
        font.pixelSize: Colors.fontSizeSmall
        font.family: Colors.fontFamily
    }
}
