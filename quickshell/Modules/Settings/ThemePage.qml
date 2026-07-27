import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

Item {
    id: root

    property string mode: "wallpaper"

    ColumnLayout {
        anchors.fill: parent
        spacing: Colors.spacing

        Text {
            text: "Aparência"
            color: Colors.foreground
            font.pixelSize: 16
            font.bold: true
        }

        RowLayout {
            spacing: Colors.spacing

            Button {
                text: "Cores do wallpaper"
                primary: root.mode === "wallpaper"
                onClicked: root.mode = "wallpaper"
            }

            Button {
                text: "Personalizar"
                primary: root.mode === "custom"
                onClicked: root.mode = "custom"
            }

            Item { Layout.fillWidth: true }
        }

        WallpaperGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "wallpaper"
        }

        ColorCustomizer {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "custom"
        }
    }
}
