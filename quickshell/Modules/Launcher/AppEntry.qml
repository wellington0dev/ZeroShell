import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Theme
import qs.Widgets

Rectangle {
    id: root

    property var entry
    property bool selected: false

    signal activated()

    radius: Styles.radiusButton
    color: selected
        ? Qt.rgba(Styles.accent.r, Styles.accent.g, Styles.accent.b, 0.16)
        : (hover.hovered ? Styles.surfaceAlt : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Styles.radiusSmall
            color: Styles.surfaceAlt

            IconImage {
                id: iconImage
                anchors.centerIn: parent
                implicitSize: 22
                source: root.entry ? Quickshell.iconPath(root.entry.icon, true) : ""
            }

            // Ícone genérico quando o app não tem ícone no tema instalado -
            // mesmo padrão de NotificationCard.qml/DockButton.qml.
            Icon {
                anchors.centerIn: parent
                visible: iconImage.status !== Image.Ready
                icon: "window"
                size: 18
                tint: Styles.foregroundMuted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.entry ? root.entry.name : ""
                color: Styles.foreground
                font.pixelSize: 13
                font.family: Styles.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.entry ? root.entry.genericName : ""
                color: Styles.foregroundMuted
                font.pixelSize: 10
                font.family: Styles.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
