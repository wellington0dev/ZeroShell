import QtQuick
import QtQuick.Layouts
import qs.Theme

ColumnLayout {
    id: root

    property var message
    readonly property bool isUser: message && message.role === "user"
    readonly property bool isTool: message && message.role === "tool"

    Layout.fillWidth: true
    spacing: 2

    Text {
        visible: !root.isUser
        text: root.isTool ? "Sistema" : "Helena"
        color: Colors.foregroundMuted
        font.pixelSize: Colors.fontSizeSmallest
        font.family: Colors.fontFamily
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.preferredWidth: Math.min(bubbleText.implicitWidth + 26, 260)
        Layout.preferredHeight: bubbleText.implicitHeight + 22
        Layout.alignment: root.isUser ? Qt.AlignRight : Qt.AlignLeft

        radius: Colors.radiusLarge
        bottomRightRadius: root.isUser ? Colors.radiusTiny : Colors.radiusLarge
        bottomLeftRadius: root.isUser ? Colors.radiusLarge : Colors.radiusTiny
        color: root.isUser ? Colors.accent : Colors.surfaceAlt
        border.color: root.isUser ? "transparent" : Colors.border
        border.width: root.isUser ? 0 : 1

        Text {
            id: bubbleText
            anchors.fill: parent
            anchors.margins: 11
            text: root.message && root.message.content
                ? root.message.content
                : (root.isTool ? "[" + (root.message.tool_name || "evento") + "]" : "")
            wrapMode: Text.Wrap
            color: root.isUser ? Colors.background : Colors.foreground
            font.pixelSize: Colors.fontSizeNormal
            font.family: Colors.fontFamily
        }
    }
}
