import QtQuick
import Quickshell
import qs.Theme
import qs.State

PanelWindow {
    id: root

    // "Notificações" desligado (Dashboard > aba Ajustes) só esconde os
    // POPUPS - o NotificationService continua registrando tudo em
    // "history" normalmente (aba Início do Dashboard), então nada se perde
    // enquanto tá "mudo", só não interrompe na hora.
    readonly property var notifications: QuickSettings.notificationsEnabled ? NotificationService.notifications : []

    visible: notifications.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins {
        top: 16
        right: 16
    }

    implicitWidth: 340
    implicitHeight: list.implicitHeight

    ListView {
        id: list

        width: parent.width
        implicitHeight: contentHeight
        model: root.notifications
        spacing: Styles.spacing
        interactive: false

        add: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation { properties: "x"; from: 40; duration: 150; easing.type: Easing.OutCubic }
        }

        remove: Transition {
            NumberAnimation { properties: "opacity"; to: 0; duration: 120 }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
            width: list.width
            notification: modelData
        }
    }
}
