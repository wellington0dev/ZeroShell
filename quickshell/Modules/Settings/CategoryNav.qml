import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    property string current: "theme"

    spacing: Colors.spacing

    IconButton {
        icon: "wifi"
        active: root.current === "wifi"
        onClicked: root.current = "wifi"
    }

    IconButton {
        icon: "bluetooth"
        active: root.current === "bluetooth"
        onClicked: root.current = "bluetooth"
    }

    IconButton {
        icon: "speaker"
        active: root.current === "audio"
        onClicked: root.current = "audio"
    }

    IconButton {
        icon: "palette"
        active: root.current === "theme"
        onClicked: root.current = "theme"
    }

    IconButton {
        icon: "camera"
        active: root.current === "capture"
        onClicked: root.current = "capture"
    }

    IconButton {
        icon: "sidebar"
        active: root.current === "sidebar"
        onClicked: root.current = "sidebar"
    }

    Item { Layout.fillHeight: true }
}
