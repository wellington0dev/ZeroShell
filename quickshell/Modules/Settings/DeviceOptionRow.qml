import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Theme

RowLayout {
    id: root

    property PwNode node
    property bool selected: false

    signal clicked()

    spacing: Colors.spacing

    Rectangle {
        width: 10
        height: 10
        radius: 5
        color: root.selected ? Colors.accent : "transparent"
        border.color: root.selected ? Colors.accent : Colors.border
        border.width: 1
    }

    Text {
        text: root.node ? (root.node.description || root.node.name) : ""
        color: root.selected ? Colors.foreground : Colors.foregroundMuted
        font.pixelSize: 12
        font.family: Colors.fontFamily
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    TapHandler { onTapped: root.clicked() }
}
