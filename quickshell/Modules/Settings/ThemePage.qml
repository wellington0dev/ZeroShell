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
            font.family: Colors.fontFamily
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

            Button {
                text: "Raio"
                primary: root.mode === "radius"
                onClicked: root.mode = "radius"
            }

            Button {
                text: "Animações"
                primary: root.mode === "motion"
                onClicked: root.mode = "motion"
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

        RadiusCustomizer {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "radius"
        }

        MotionCustomizer {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "motion"
        }
    }
}
