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
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.preferredWidth: Math.min(bubbleText.implicitWidth + 22, 240)
        Layout.preferredHeight: bubbleText.implicitHeight + 18
        Layout.alignment: root.isUser ? Qt.AlignRight : Qt.AlignLeft

        radius: Colors.radiusMedium
        bottomRightRadius: root.isUser ? Colors.radiusTiny : Colors.radiusMedium
        bottomLeftRadius: root.isUser ? Colors.radiusMedium : Colors.radiusTiny
        color: root.isUser ? Colors.accent : Colors.surfaceAlt

        Text {
            id: bubbleText
            anchors.fill: parent
            anchors.margins: 9
            text: root.message && root.message.content
                ? root.message.content
                : (root.isTool ? "[" + (root.message.tool_name || "evento") + "]" : "")
            wrapMode: Text.Wrap
            color: root.isUser ? Colors.background : Colors.foreground
            font.pixelSize: Colors.fontSizeNormal
        }
    }
}
