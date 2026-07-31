pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Toggles rápidos do shell (aba "Ajustes" do Dashboard - QuickSettingsTab.qml):
// notificações e "manter acordado". Cada um é lido por um módulo diferente
// que nem se conhece diretamente (NotificationPopups.qml, LockScreen.qml,
// Sidebar.qml) - esse singleton é o ponto de encontro, mesmo raciocínio do
// State/Visibility.qml.
Singleton {
    id: root

    // Persistido (JSON) - "mudo" é uma preferência que devia sobreviver a um
    // reinício do quickshell, senão o usuário desligaria de novo toda vez.
    readonly property bool notificationsEnabled: adapter.notificationsEnabled

    function setNotificationsEnabled(value) {
        adapter.notificationsEnabled = value
        settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/quick-settings.json"

        JsonAdapter {
            id: adapter
            property bool notificationsEnabled: true
        }
    }

    // "Manter acordado" NÃO é persistido de propósito - é um estado
    // temporário ("tô assistindo algo agora"), não uma preferência
    // duradoura. Persistir isso faria a tela nunca mais travar sozinha se o
    // usuário esquecesse de desligar antes de fechar a sessão.
    property bool keepAwake: false

    function setKeepAwake(value) {
        root.keepAwake = value
    }
}
