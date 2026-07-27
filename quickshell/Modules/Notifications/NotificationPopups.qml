import QtQuick
import Quickshell
import qs.Theme

PanelWindow {
    id: root

    readonly property var notifications: NotificationService.notifications

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
        spacing: Colors.spacing
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
