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
        radius: Styles.radiusButton
        color: root.selected
            ? Qt.rgba(Styles.accent.r, Styles.accent.g, Styles.accent.b, 0.18)
            : (hover.hovered ? Styles.surfaceAlt : Styles.surface)
        border.color: root.selected ? Styles.accent : Styles.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Motion.durationFast } }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 22
            tint: root.selected ? Styles.accent : Styles.foreground
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: root.activated() }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: root.selected ? Styles.accent : Styles.foregroundMuted
        font.pixelSize: Styles.fontSizeSmall
        font.family: Styles.fontFamily
    }
}
