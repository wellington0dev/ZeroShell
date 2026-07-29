import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.Theme

RowLayout {
    id: root

    property string label
    property string key
    property color value

    signal changed(string key, color value)

    spacing: Colors.spacing

    Text {
        text: root.label
        color: Colors.foreground
        font.pixelSize: 12
        font.family: Colors.fontFamily
        Layout.fillWidth: true
    }

    Text {
        text: root.value.toString()
        color: Colors.foregroundMuted
        font.pixelSize: 11
        font.family: Colors.fontFamily
    }

    Rectangle {
        width: 24
        height: 24
        radius: Colors.radiusSmall
        color: root.value
        border.color: Colors.border
        border.width: 1

        TapHandler { onTapped: dialog.open() }
    }

    ColorDialog {
        id: dialog
        selectedColor: root.value
        onAccepted: root.changed(root.key, selectedColor)
    }
}
