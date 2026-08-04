import Quickshell.Io
import qs.Widgets

// Ícone na sidebar deste plugin (ver "sidebar.component" no plugin.json).
// Só chama IPC - não tem nenhuma referência direta ao Main.qml (arquivo
// irmão), porque cada um é carregado por um Loader separado pelo
// PluginService. Ver o comentário grande em Main.qml pra entender por quê.
IconButton {
    icon: "window"
    size: 28

    Process { id: toggleProcess; command: ["qs", "ipc", "call", "windowexample", "toggle"] }

    onClicked: toggleProcess.running = true
}
