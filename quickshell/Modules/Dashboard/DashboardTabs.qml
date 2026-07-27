import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Barra de abas horizontal do Dashboard - ícone + rótulo, só 3 itens então
// dá pra escrever o nome (diferente da CategoryNav das Configurações, que é
// só ícone por ter uma coluna estreita).
RowLayout {
    id: root

    property string current: "home"
    spacing: Colors.spacing

    readonly property var tabs: [
        { key: "home", icon: "home", label: "Início" },
        { key: "player", icon: "music-note", label: "Player" },
        { key: "system", icon: "cpu", label: "Sistema" }
    ]

    Repeater {
        model: root.tabs

        delegate: Rectangle {
            id: tab

            required property var modelData

            readonly property bool active: root.current === modelData.key

            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Colors.radiusMedium
            color: active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : (hover.hovered ? Colors.surfaceAlt : "transparent")
            border.color: active ? Colors.accent : "transparent"
            border.width: 1

            Behavior on color { ColorAnimation { duration: Motion.durationFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Icon {
                    icon: tab.modelData.icon
                    size: 16
                    tint: tab.active ? Colors.accent : Colors.foregroundMuted
                }

                Text {
                    text: tab.modelData.label
                    color: tab.active ? Colors.accent : Colors.foregroundMuted
                    font.pixelSize: Colors.fontSizeSmall
                }
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: root.current = tab.modelData.key }
        }
    }
}
