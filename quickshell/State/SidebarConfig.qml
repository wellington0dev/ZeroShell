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
    property bool showHelena: adapter.showHelena
    property bool showVoice: adapter.showVoice
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

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/sidebar-config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool showProfile: true
            property bool showLauncher: true
            property bool showHelena: true
            property bool showVoice: true
            property bool showWorkspaces: true
            property bool showAppTray: true
            property bool showClock: true
            property bool showBattery: true
            property bool showCapture: true
            property bool showSettings: true
            property bool showPower: true
        }
    }
}
