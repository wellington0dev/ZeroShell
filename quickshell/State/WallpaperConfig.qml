pragma Singleton

import Quickshell
import Quickshell.Io

// Recuo + arredondamento do wallpaper (Modules/Wallpaper/WallpaperWindow.qml)
// em relação às 4 bordas da tela - editável em Configurações > categoria de
// wallpaper (Modules/Settings/WallpaperGrid.qml). Persistido em
// State/wallpaper-config.json, mesmo padrão de DockConfig.qml.
//
// Sem "enabled" de propósito: "margin" 0 já É o estado "desligado" (cantos
// arredondam rente ao pixel real da tela, sem vão nenhum) - substitui o
// antigo ScreenBorderConfig (borda/bezel sólido à parte, removido), que
// tinha um toggle separado.
Singleton {
    id: root

    property int margin: adapter.margin
    property int radius: adapter.radius

    function setMargin(value) {
        adapter.margin = value
        file.writeAdapter()
    }

    function setRadius(value) {
        adapter.radius = value
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/wallpaper-config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property int margin: 0
            property int radius: 15
        }
    }
}
