pragma Singleton

import Quickshell
import Quickshell.Io

// Quais apps ficam fixados no dock - editável em Configurações > aba "Dock"
// (Modules/Settings/DockPage.qml). Persistido em State/dock-config.json,
// mesmo padrão de SidebarConfig.qml.
//
// Guarda só o "id" do DesktopEntry (ver Quickshell.DesktopEntries.byId) -
// não o objeto inteiro, que não sobrevive a um restart do shell. O
// DockWindow.qml resolve os ids de volta pra DesktopEntry na hora de
// desenhar.
Singleton {
    id: root

    property var pinnedIds: adapter.pinnedIds

    function isPinned(id) {
        return root.pinnedIds.includes(id)
    }

    function setPinned(id, value) {
        const rest = adapter.pinnedIds.filter(i => i !== id)
        adapter.pinnedIds = value ? [...rest, id] : rest
        file.writeAdapter()
    }

    // ---- O DOCK em si fixado ou não (botão de pin no canto do dock) ----
    // Não confundir com "pinnedIds" acima (quais APPS aparecem fixados
    // DENTRO do dock) - "pinned" aqui é se o PAINEL do dock fica sempre
    // visível reservando espaço na tela (empurra janelas, ver
    // DockWindow.qml) ou se esconde sozinho e só aparece ao passar o mouse
    // na borda inferior. Desligado por padrão - o dock nasce como overlay
    // flutuante, igual sempre foi antes desse botão existir.
    property bool pinned: adapter.pinned

    function setDockPinned(value) {
        adapter.pinned = value
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/dock-config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property var pinnedIds: []
            property bool pinned: false
        }
    }
}
