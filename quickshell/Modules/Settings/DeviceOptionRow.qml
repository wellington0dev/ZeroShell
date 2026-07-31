import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Theme

RowLayout {
    id: root

    property PwNode node
    property bool selected: false

    signal clicked()

    spacing: Styles.spacing

    Rectangle {
        width: 10
        height: 10
        radius: 5
        color: root.selected ? Styles.accent : "transparent"
        border.color: root.selected ? Styles.accent : Styles.border
        border.width: 1
    }

    Text {
        text: root.node ? (root.node.description || root.node.name) : ""
        color: root.selected ? Styles.foreground : Styles.foregroundMuted
        font.pixelSize: 12
        font.family: Styles.fontFamily
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    TapHandler { onTapped: root.clicked() }
}
