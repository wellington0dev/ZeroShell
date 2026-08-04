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
        // open/close explícitos (além do toggle acima) - scripts que
        // precisam de estado determinístico (ex.: debug-shell.sh) não podem
        // usar um toggle cego sem saber o estado atual antes.
        function open(): void { Visibility.settingsOpen = true }
        function close(): void { Visibility.settingsOpen = false }

        // Troca a categoria ativa - "wifi", "bluetooth", "audio", "theme",
        // "capture", "sidebar", "plugins", "dock" ou "keybinds" (ver
        // Modules/Settings/CategoryNav.qml). Não valida o nome: um valor
        // inválido só faz o Loader acima cair no "default" (null, painel
        // vazio), sem quebrar nada.
        function category(name: string): void { Visibility.settingsCategory = name }
    }

    title: "Configurações"
    visible: Visibility.settingsOpen
    color: Styles.background

    implicitWidth: 720
    implicitHeight: 480
    minimumSize: Qt.size(600, 420)

    onClosed: Visibility.settingsOpen = false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Styles.spacing * 2
        spacing: Styles.spacing * 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Icon {
                icon: "gear"
                size: 18
                tint: Styles.foreground
            }

            Text {
                text: "Configurações"
                color: Styles.foreground
                font.pixelSize: 18
                font.family: Styles.fontFamily
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
            spacing: Styles.spacing * 2

            CategoryNav {
                id: nav
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Styles.border
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
                        case "plugins": return pluginsPageComp
                        case "dock": return dockPageComp
                        case "keybinds": return keybindsPageComp
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
    Component { id: pluginsPageComp; PluginsPage {} }
    Component { id: dockPageComp; DockPage {} }
    Component { id: keybindsPageComp; KeybindsPage {} }
}
