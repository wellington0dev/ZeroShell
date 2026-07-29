import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State

ColumnLayout {
    id: root

    // Vive em Visibility.settingsCategory (não como property local) pra dar
    // pra trocar de categoria de fora via IPC (hypr/scripts/debug-shell*.sh).
    readonly property string current: Visibility.settingsCategory

    spacing: Colors.spacing

    IconButton {
        icon: "wifi"
        active: root.current === "wifi"
        onClicked: Visibility.settingsCategory = "wifi"
    }

    IconButton {
        icon: "bluetooth"
        active: root.current === "bluetooth"
        onClicked: Visibility.settingsCategory = "bluetooth"
    }

    IconButton {
        icon: "speaker"
        active: root.current === "audio"
        onClicked: Visibility.settingsCategory = "audio"
    }

    IconButton {
        icon: "palette"
        active: root.current === "theme"
        onClicked: Visibility.settingsCategory = "theme"
    }

    IconButton {
        icon: "camera"
        active: root.current === "capture"
        onClicked: Visibility.settingsCategory = "capture"
    }

    IconButton {
        icon: "sidebar"
        active: root.current === "sidebar"
        onClicked: Visibility.settingsCategory = "sidebar"
    }

    Item { Layout.fillHeight: true }
}
