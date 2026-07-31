import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    property string icon
    property string label
    property bool needsConfirm: false
    property color tint: Styles.foreground

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
        radius: Styles.radiusButton
        color: root.confirming
            ? Qt.rgba(Styles.danger.r, Styles.danger.g, Styles.danger.b, 0.18)
            : (hover.hovered ? Styles.surfaceAlt : Styles.surface)
        border.color: root.confirming ? Styles.danger : Styles.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: Motion.durationFast } }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 26
            tint: root.confirming ? Styles.danger : root.tint
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
        color: root.confirming ? Styles.danger : Styles.foregroundMuted
        font.pixelSize: Styles.fontSizeSmall
        font.family: Styles.fontFamily
    }
}
