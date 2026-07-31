import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Plugins

// Aba de Configurações pra escolher quais itens aparecem na sidebar. Cada
// linha liga/desliga um item guardado em SidebarConfig (State/SidebarConfig.qml,
// persistido em State/sidebar-config.json) - a própria Sidebar.qml lê essas
// mesmas propriedades pra decidir o que desenhar.
//
// A lista mistura os itens fixos do shell (abaixo) com um item por plugin
// instalado que declarou "sidebar.component" no manifesto - ver
// "pluginItems". Plugin ligado na aba Plugins NÃO liga o ícone sozinho:
// o usuário escolhe aqui, um por um (ver SidebarConfig.isPluginIconVisible).
Item {
    id: root

    readonly property var items: [
        { key: "showProfile",    label: "Foto de perfil" },
        { key: "showLauncher",   label: "Lançador de apps" },
        { key: "showWorkspaces", label: "Workspaces" },
        { key: "showAppTray",    label: "Apps em segundo plano" },
        { key: "showClock",      label: "Relógio" },
        { key: "showBattery",    label: "Bateria" },
        { key: "showCapture",    label: "Captura de tela" },
        { key: "showSettings",   label: "Configurações" },
        { key: "showPower",      label: "Menu de energia" }
    ]

    readonly property var pluginItems: PluginService.plugins
        .filter(p => p.enabled && p.sidebar && p.sidebar.component)
        .map(p => ({ key: p.id, label: (p.name || p.id) + " (plugin)", isPlugin: true }))

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing

        Text {
            text: "Sidebar"
            color: Styles.foreground
            font.pixelSize: 16
            font.family: Styles.fontFamily
            font.bold: true
        }

        Text {
            text: "Escolha quais itens aparecem na barra lateral."
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Styles.spacing
            model: root.items.concat(root.pluginItems)

            delegate: RowLayout {
                width: ListView.view.width

                Text {
                    text: modelData.label
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                }

                Switch {
                    checked: modelData.isPlugin
                        ? SidebarConfig.isPluginIconVisible(modelData.key)
                        : SidebarConfig[modelData.key]
                    onToggled: modelData.isPlugin
                        ? SidebarConfig.setPluginIconVisible(modelData.key, !SidebarConfig.isPluginIconVisible(modelData.key))
                        : SidebarConfig.set(modelData.key, !SidebarConfig[modelData.key])
                }
            }
        }
    }
}
