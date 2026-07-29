import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.Theme
import qs.Widgets

Rectangle {
    id: root

    // "var", não "Notification": no popup é o objeto Notification ao vivo,
    // mas no histórico do Dashboard (isPopup: false) é uma cópia simples dos
    // dados (ver NotificationService.qml) - um tipo QML forte rejeitaria essa
    // segunda forma.
    property var notification

    // false na lista do Dashboard (HomeTab.qml): ali o card representa
    // histórico persistente, não deve sumir sozinho enquanto ninguém olha -
    // só nos popups (NotificationPopups.qml) o timeout deve valer.
    property bool isPopup: true

    readonly property int urgency: notification ? notification.urgency : NotificationUrgency.Normal
    readonly property color urgencyColor: urgency === NotificationUrgency.Critical ? Colors.danger : Colors.accent
    readonly property bool autoExpires: root.isPopup && urgency !== NotificationUrgency.Critical
    readonly property int timeoutMs: notification && notification.expireTimeout > 0
        ? notification.expireTimeout * 1000
        : 5000

    // notification.image comes pre-resolved from Quickshell (file:// path or an
    // image:// provider URL for pixmap/theme-name data) - use it as-is. appIcon
    // is still a raw icon-theme-name-or-path string that we need to resolve ourselves.
    function resolveAppIcon(path) {
        if (!path) return ""
        if (path.startsWith("file://") || path.startsWith("http") || path.startsWith("image://")) return path
        if (path.startsWith("/")) return "file://" + path
        return Quickshell.iconPath(path, true)
    }

    width: 340
    implicitHeight: content.implicitHeight + 24
    radius: Colors.radiusShell
    color: Colors.surface
    border.color: urgencyColor
    border.width: 1
    clip: true

    TapHandler {
        onTapped: {
            if (!root.notification) return
            const def = root.notification.actions.find(a => a.identifier === "default")
            if (def) def.invoke()
        }
    }

    Timer {
        running: root.notification && root.autoExpires
        interval: root.timeoutMs
        onTriggered: if (root.notification) root.notification.expire()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 10
                color: Colors.surfaceAlt

                Image {
                    id: iconImage
                    anchors.fill: parent
                    anchors.margins: 4
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                    source: root.notification
                        ? (root.notification.image || root.resolveAppIcon(root.notification.appIcon))
                        : ""
                }

                Icon {
                    anchors.centerIn: parent
                    visible: iconImage.status !== Image.Ready
                    icon: "bell"
                    size: 18
                    tint: Colors.foregroundMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.notification ? root.notification.appName : ""
                    color: Colors.foregroundMuted
                    font.pixelSize: 10
                    font.family: Colors.fontFamily
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.notification ? root.notification.summary : ""
                    color: Colors.foreground
                    font.pixelSize: 13
                    font.family: Colors.fontFamily
                    font.bold: true
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            IconButton {
                size: 24
                icon: "close"
                onClicked: {
                    if (!root.notification) return
                    // No histórico (Dashboard) "notification" é uma cópia
                    // simples dos dados, não o objeto Notification ao vivo -
                    // não tem .dismiss(), some da lista via removeFromHistory.
                    if (root.isPopup) root.notification.dismiss()
                    else NotificationService.removeFromHistory(root.notification.id)
                }
            }
        }

        Text {
            visible: text.length > 0
            text: root.notification ? root.notification.body : ""
            color: Colors.foregroundMuted
            font.pixelSize: 12
            font.family: Colors.fontFamily
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.notification && root.notification.actions.length > 0

            Repeater {
                model: root.notification ? root.notification.actions : []

                delegate: Button {
                    text: modelData.text
                    primary: false
                    onClicked: modelData.invoke()
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        radius: 1
        color: root.urgencyColor
        opacity: 0.7
        visible: root.autoExpires

        NumberAnimation on width {
            running: root.autoExpires
            from: root.width
            to: 0
            duration: root.timeoutMs
        }
    }
}
