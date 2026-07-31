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

    spacing: Styles.spacing

    Text {
        text: root.label
        color: Styles.foreground
        font.pixelSize: 12
        font.family: Styles.fontFamily
        Layout.fillWidth: true
    }

    Text {
        text: root.value.toString()
        color: Styles.foregroundMuted
        font.pixelSize: 11
        font.family: Styles.fontFamily
    }

    Rectangle {
        width: 24
        height: 24
        radius: Styles.radiusSmall
        color: root.value
        border.color: Styles.border
        border.width: 1

        TapHandler { onTapped: dialog.open() }
    }

    ColorDialog {
        id: dialog
        selectedColor: root.value
        onAccepted: root.changed(root.key, selectedColor)
    }
}
