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
            property bool showCapture: true
            property bool showSettings: true
            property bool showPower: true
            property var pluginIcons: []
        }
    }
}
