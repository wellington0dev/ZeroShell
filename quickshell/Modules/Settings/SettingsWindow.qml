import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets
import qs.State

FloatingWindow {
    id: root

    IpcHandler {
        target: "settings"

        // Bound ao keybind SUPER+C no hyprland.lua:
        // qs ipc call settings toggle
        function toggle(): void {
            Visibility.settingsOpen = !Visibility.settingsOpen
        }
    }

    title: "Configurações"
    visible: Visibility.settingsOpen
    color: Colors.background

    implicitWidth: 720
    implicitHeight: 480
    minimumSize: Qt.size(600, 420)

    onClosed: Visibility.settingsOpen = false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacing * 2
        spacing: Colors.spacing * 2

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Configurações"
                color: Colors.foreground
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                onClicked: Visibility.settingsOpen = false
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Colors.spacing * 2

            CategoryNav {
                id: nav
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Colors.border
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: Visibility.settingsOpen
                sourceComponent: {
                    switch (nav.current) {
                        case "wifi": return wifiPageComp
                        case "bluetooth": return bluetoothPageComp
                        case "audio": return audioPageComp
                        case "theme": return themePageComp
                        case "capture": return capturePageComp
                        case "sidebar": return sidebarPageComp
                        default: return null
                    }
                }
            }
        }
    }

    Component { id: wifiPageComp; WifiPage {} }
    Component { id: bluetoothPageComp; BluetoothPage {} }
    Component { id: audioPageComp; AudioPage {} }
    Component { id: themePageComp; ThemePage {} }
    Component { id: capturePageComp; CapturePage {} }
    Component { id: sidebarPageComp; SidebarPage {} }
}
