import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State

// Aba de Configurações pra escolher quais itens aparecem na sidebar. Cada
// linha liga/desliga um item guardado em SidebarConfig (State/SidebarConfig.qml,
// persistido em State/sidebar-config.json) - a própria Sidebar.qml lê essas
// mesmas propriedades pra decidir o que desenhar.
Item {
    id: root

    readonly property var items: [
        { key: "showProfile",    label: "Foto de perfil" },
        { key: "showLauncher",   label: "Lançador de apps" },
        { key: "showHelena",     label: "Chat da Helena" },
        { key: "showVoice",      label: "Chat de voz da Helena" },
        { key: "showWorkspaces", label: "Workspaces" },
        { key: "showAppTray",    label: "Apps em segundo plano" },
        { key: "showClock",      label: "Relógio" },
        { key: "showBattery",    label: "Bateria" },
        { key: "showCapture",    label: "Captura de tela" },
        { key: "showSettings",   label: "Configurações" },
        { key: "showPower",      label: "Menu de energia" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: Colors.spacing

        Text {
            text: "Sidebar"
            color: Colors.foreground
            font.pixelSize: 16
            font.family: Colors.fontFamily
            font.bold: true
        }

        Text {
            text: "Escolha quais itens aparecem na barra lateral."
            color: Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            font.family: Colors.fontFamily
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Colors.spacing
            model: root.items

            delegate: RowLayout {
                width: ListView.view.width

                Text {
                    text: modelData.label
                    color: Colors.foreground
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontFamily
                    Layout.fillWidth: true
                }

                Switch {
                    checked: SidebarConfig[modelData.key]
                    onToggled: SidebarConfig.set(modelData.key, !SidebarConfig[modelData.key])
                }
            }
        }
    }
}
