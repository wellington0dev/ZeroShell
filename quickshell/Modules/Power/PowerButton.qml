import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    property string icon
    property string label
    property bool needsConfirm: false
    property color tint: Colors.foreground

    signal activated()

    property bool confirming: false

    spacing: 6

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: root.confirming = false
    }

    Rectangle {
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        Layout.alignment: Qt.AlignHCenter
        radius: Colors.radiusMedium
        color: root.confirming
            ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18)
            : (hover.hovered ? Colors.surfaceAlt : Colors.surface)
        border.color: root.confirming ? Colors.danger : Colors.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Motion.durationFast } }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 26
            tint: root.confirming ? Colors.danger : root.tint
        }

        HoverHandler { id: hover }
        TapHandler {
            onTapped: {
                if (!root.needsConfirm || root.confirming) {
                    root.confirming = false
                    root.activated()
                } else {
                    root.confirming = true
                    resetTimer.restart()
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.confirming ? "Confirmar?" : root.label
        color: root.confirming ? Colors.danger : Colors.foregroundMuted
        font.pixelSize: Colors.fontSizeSmall
    }
}
