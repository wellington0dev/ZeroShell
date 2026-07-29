import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Theme

Rectangle {
    id: root

    property var entry
    property bool selected: false

    signal activated()

    radius: Colors.radiusButton
    color: selected
        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
        : (hover.hovered ? Colors.surfaceAlt : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Colors.radiusSmall
            color: Colors.surfaceAlt

            IconImage {
                anchors.centerIn: parent
                implicitSize: 22
                source: root.entry ? Quickshell.iconPath(root.entry.icon, true) : ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.entry ? root.entry.name : ""
                color: Colors.foreground
                font.pixelSize: 13
                font.family: Colors.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.entry ? root.entry.genericName : ""
                color: Colors.foregroundMuted
                font.pixelSize: 10
                font.family: Colors.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
