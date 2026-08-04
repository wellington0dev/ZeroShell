pragma Singleton

import Quickshell
import Quickshell.Io

// Quais itens aparecem na sidebar - editável em Configurações > aba
// "sidebar" (Modules/Settings/SidebarPage.qml). Persistido em
// State/sidebar-config.json, igual ao padrão usado em CaptureService.
Singleton {
    id: root

    property bool showProfile: adapter.showProfile
    property bool showLauncher: adapter.showLauncher
    property bool showWorkspaces: adapter.showWorkspaces
    property bool showAppTray: adapter.showAppTray
    property bool showClock: adapter.showClock
    property bool showBattery: adapter.showBattery
    property bool showWifi: adapter.showWifi
    property bool showBluetooth: adapter.showBluetooth
    property bool showCapture: adapter.showCapture
    property bool showSettings: adapter.showSettings
    property bool showPower: adapter.showPower

    function set(key, value) {
        adapter[key] = value
        file.writeAdapter()
    }

    // ---- Ícone de plugin na sidebar - opt-in, não automático ----
    // Ao contrário dos itens fixos acima, plugin instalado+ligado não basta
    // pra ganhar ícone na sidebar: o usuário precisa marcar isso aqui
    // também (aba "sidebar" das Configurações lista um item por plugin que
    // declarou "sidebar.component"). Desligado por padrão de propósito -
    // instalar/ligar um plugin não deve mudar a sidebar sozinho.
    // Mesmo padrão array-de-objetos do PluginService (overrides), pelo
    // mesmo motivo: chave dinâmica (um id por plugin instalado).
    property var pluginIcons: adapter.pluginIcons

    function isPluginIconVisible(id) {
        const entry = pluginIcons.find(o => o.id === id)
        return entry ? !!entry.visible : false
    }

    function setPluginIconVisible(id, value) {
        const rest = adapter.pluginIcons.filter(o => o.id !== id)
        adapter.pluginIcons = [...rest, { id: id, visible: value }]
        file.writeAdapter()
    }

    // ---- Em qual terço da coluna cada item aparece: "top"/"center"/"bottom" ----
    // Não é posição exata, é o GRUPO (Sidebar.qml desenha 3 sub-colunas
    // separadas por 2 espaçadores elásticos, igual os Workspaces sempre
    // usaram pra ficar no centro - agora qualquer item pode ir pra lá).
    // Dentro do mesmo grupo os itens mantêm a ordem "natural" (a ordem em
    // que aparecem no array de builtins do Sidebar.qml), não a ordem que o
    // usuário clicou.
    //
    // "id" aqui é uma chave curta (ver defaultAlign) pros itens fixos, ou o
    // id do plugin pros ícones de plugin - mesmo padrão array-de-objetos de
    // "pluginIcons"/"overrides" acima e no PluginService, pelo mesmo motivo
    // (chave dinâmica).
    readonly property var defaultAlign: ({
        profile: "top",
        launcher: "top",
        workspaces: "center",
        appTray: "bottom",
        clock: "bottom",
        battery: "bottom",
        wifi: "bottom",
        bluetooth: "bottom",
        capture: "bottom",
        settings: "bottom",
        power: "bottom"
    })

    property var itemAlign: adapter.itemAlign

    function getAlign(id) {
        const entry = itemAlign.find(o => o.id === id)
        if (entry) return entry.align
        // Ícone de plugin sem escolha salva ainda: fica no rodapé, igual
        // sempre esteve antes desse sistema existir.
        return root.defaultAlign[id] || "bottom"
    }

    function setAlign(id, value) {
        const rest = adapter.itemAlign.filter(o => o.id !== id)
        adapter.itemAlign = [...rest, { id: id, align: value }]
        file.writeAdapter()
    }

    // ---- Ordem de cada item DENTRO do seu grupo (topo/centro/rodapé) ----
    // Número só serve pra ordenar (sort) os itens de um mesmo grupo entre
    // si - não precisa ser sequencial nem sem buracos, só a ordem relativa
    // importa. Trocado pelos botões "▲"/"▼" na aba Sidebar das
    // Configurações (Modules/Settings/SidebarPage.qml), que só reordenam
    // dentro do MESMO grupo (swap do valor com o vizinho).
    //
    // Sem valor salvo ainda, quem chama passa a posição "natural" do item
    // como "fallback" (índice no array combinado fixos+plugins - ver
    // Sidebar.qml/SidebarPage.qml), preservando a ordem original até o
    // usuário mexer pela primeira vez.
    property var itemOrder: adapter.itemOrder

    function getOrder(id, fallback) {
        const entry = itemOrder.find(o => o.id === id)
        return entry ? entry.order : (fallback ?? 0)
    }

    function setOrder(id, value) {
        const rest = adapter.itemOrder.filter(o => o.id !== id)
        adapter.itemOrder = [...rest, { id: id, order: value }]
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/sidebar-config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool showProfile: true
            property bool showLauncher: true
            property bool showWorkspaces: true
            property bool showAppTray: true
            property bool showClock: true
            property bool showBattery: true
            property bool showWifi: true
            property bool showBluetooth: true
            property bool showCapture: true
            property bool showSettings: true
            property bool showPower: true
            property var pluginIcons: []
            property var itemAlign: []
            property var itemOrder: []
        }
    }
}
