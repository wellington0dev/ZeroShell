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

    // "key" é a property booleana em SidebarConfig (liga/desliga o item -
    // Switch abaixo). "alignId" é a chave curta usada por
    // SidebarConfig.getAlign/setAlign (grupo topo/centro/rodapé, ver
    // Sidebar.qml) - propositalmente separada de "key" porque
    // liga/desliga e grupo são duas escolhas independentes.
    // "fallbackOrder" tem que ser calculado no MESMO esquema que
    // Sidebar.qml usa (fixos: índice 0-8 na ordem declarada abaixo;
    // plugins: 100 + índice de descoberta) - senão as setas ▲▼ e o que a
    // sidebar de verdade desenha divergiam na primeira vez que o usuário
    // reordena algo sem valor salvo ainda.
    readonly property var items: [
        { key: "showProfile",    alignId: "profile",    label: "Foto de perfil" },
        { key: "showLauncher",   alignId: "launcher",   label: "Lançador de apps" },
        { key: "showWorkspaces", alignId: "workspaces", label: "Workspaces" },
        { key: "showAppTray",    alignId: "appTray",    label: "Apps em segundo plano" },
        { key: "showClock",      alignId: "clock",      label: "Relógio" },
        { key: "showBattery",    alignId: "battery",    label: "Bateria" },
        { key: "showWifi",       alignId: "wifi",       label: "Wi-Fi" },
        { key: "showBluetooth",  alignId: "bluetooth",  label: "Bluetooth" },
        { key: "showCapture",    alignId: "capture",    label: "Captura de tela" },
        { key: "showSettings",   alignId: "settings",   label: "Configurações" },
        { key: "showPower",      alignId: "power",      label: "Menu de energia" }
    ].map((it, idx) => ({ key: it.key, alignId: it.alignId, label: it.label, fallbackOrder: idx }))

    readonly property var pluginItems: PluginService.plugins
        .map((p, idx) => ({ p: p, fallbackOrder: 100 + idx }))
        .filter(o => o.p.enabled && o.p.sidebar && o.p.sidebar.component)
        .map(o => ({ key: o.p.id, alignId: o.p.id, label: (o.p.name || o.p.id) + " (plugin)", isPlugin: true, fallbackOrder: o.fallbackOrder }))

    // Lista combinada com o "order" já resolvido (salvo ou fallback) - as
    // funções moveUp/moveDown abaixo reordenam DENTRO do mesmo grupo
    // (align), igual Sidebar.qml faz pra desenhar.
    readonly property var merged: root.items.concat(root.pluginItems)

    function siblingsOf(item) {
        const group = SidebarConfig.getAlign(item.alignId)
        return root.merged
            .filter(i => SidebarConfig.getAlign(i.alignId) === group)
            .sort((a, b) => SidebarConfig.getOrder(a.alignId, a.fallbackOrder) - SidebarConfig.getOrder(b.alignId, b.fallbackOrder))
    }

    function swapOrder(a, b) {
        const orderA = SidebarConfig.getOrder(a.alignId, a.fallbackOrder)
        const orderB = SidebarConfig.getOrder(b.alignId, b.fallbackOrder)
        SidebarConfig.setOrder(a.alignId, orderB)
        SidebarConfig.setOrder(b.alignId, orderA)
    }

    function moveUp(item) {
        const siblings = root.siblingsOf(item)
        const idx = siblings.findIndex(i => i.alignId === item.alignId)
        if (idx > 0) root.swapOrder(item, siblings[idx - 1])
    }

    function moveDown(item) {
        const siblings = root.siblingsOf(item)
        const idx = siblings.findIndex(i => i.alignId === item.alignId)
        if (idx !== -1 && idx < siblings.length - 1) root.swapOrder(item, siblings[idx + 1])
    }

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
            model: root.merged

            delegate: RowLayout {
                id: row

                required property var modelData

                width: ListView.view.width
                spacing: Styles.spacing

                Text {
                    text: row.modelData.label
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                }

                // Grupo dentro da coluna da sidebar - ver
                // SidebarConfig.getAlign/setAlign e o comentário grande em
                // Sidebar.qml sobre as 3 sub-colunas.
                RowLayout {
                    spacing: 4

                    Button {
                        text: "Topo"
                        primary: SidebarConfig.getAlign(row.modelData.alignId) === "top"
                        onClicked: SidebarConfig.setAlign(row.modelData.alignId, "top")
                    }

                    Button {
                        text: "Centro"
                        primary: SidebarConfig.getAlign(row.modelData.alignId) === "center"
                        onClicked: SidebarConfig.setAlign(row.modelData.alignId, "center")
                    }

                    Button {
                        text: "Rodapé"
                        primary: SidebarConfig.getAlign(row.modelData.alignId) === "bottom"
                        onClicked: SidebarConfig.setAlign(row.modelData.alignId, "bottom")
                    }
                }

                Switch {
                    checked: row.modelData.isPlugin
                        ? SidebarConfig.isPluginIconVisible(row.modelData.key)
                        : SidebarConfig[row.modelData.key]
                    onToggled: row.modelData.isPlugin
                        ? SidebarConfig.setPluginIconVisible(row.modelData.key, !SidebarConfig.isPluginIconVisible(row.modelData.key))
                        : SidebarConfig.set(row.modelData.key, !SidebarConfig[row.modelData.key])
                }

                // Posição dentro do grupo atual (topo/centro/rodapé) - só
                // reordena entre os vizinhos do MESMO grupo (ver
                // root.moveUp/moveDown), então mover um item pra outro
                // grupo primeiro (botões acima) muda quem são os vizinhos.
                RowLayout {
                    spacing: 2

                    IconButton {
                        icon: "skip-previous"
                        rotation: 90
                        size: 24
                        onClicked: root.moveUp(row.modelData)
                    }

                    IconButton {
                        icon: "skip-next"
                        rotation: 90
                        size: 24
                        onClicked: root.moveDown(row.modelData)
                    }
                }
            }
        }
    }
}
