pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Descobre plugins instalados em ~/.config/quickshell/plugins/<id>/ - cada
// pasta com um plugin.json válido vira um item em "plugins" abaixo (ver
// scripts/scan-plugins.sh, que faz a leitura de verdade em Python - QML
// sozinho não lista diretório).
//
// NÃO é reativo a mudanças no disco: instalar um plugin novo exige clicar
// "Atualizar" na aba Plugins das Configurações (chama rescan()), não fica
// re-escaneando sozinho o tempo todo - instalar plugin é uma ação
// deliberada e rara do usuário, não precisa de polling constante tipo
// SystemStats.qml.
//
// Cada plugin pode declarar até 4 pontos de integração no manifesto, todos
// opcionais:
//   "main": componente carregado permanentemente (igual Sidebar{}/
//     PowerMenu{} em shell.qml) - onde mora IPC/timers/lógica de fundo.
//     Não existe um campo separado tipo "ipc: true" no manifesto - se o
//     plugin quer um IpcHandler, ele só bota um dentro do "main"; o
//     Quickshell registra sozinho assim que o componente é instanciado.
//   "sidebar.component": ícone próprio na barra lateral (Sidebar.qml) - só
//     aparece de verdade se o usuário também marcar o plugin na aba
//     "sidebar" das Configurações (ver State/SidebarConfig.qml,
//     isPluginIconVisible) - ligar o plugin aqui não basta sozinho.
//   "settingsPage": página mostrada na aba "Plugins" das Configurações.
//   "testScript": script (bash, relativo à pasta do plugin) que a aba
//     Plugins roda sob demanda (botão "play") pra testar se o plugin tá
//     funcionando - exit code 0 = passou, qualquer outro = falhou. Não
//     roda sozinho nunca, só quando o usuário clica.
//
// Um plugin é só QML com o mesmo acesso a Process/Quickshell.execDetached
// que o resto do shell tem - não tem sandboxing nenhum, de propósito (mesma
// confiança de editar o shell direto, como plugins de nvim/tmux). Só
// instale plugin em que você confia.
Singleton {
    id: root

    readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/quickshell/plugins"
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/Modules/Plugins/scripts/scan-plugins.sh"

    // Cada item: manifesto original (id/name/version/description/main/
    // sidebar/settingsPage) + "dir" (path absoluto da pasta, injetado pelo
    // script) + "enabled" (ligado/desligado pelo usuário, ver
    // isEnabled/setEnabled abaixo).
    property var plugins: []

    function rescan() {
        scanProcess.running = true
    }

    // Disparado quando um rescan() de verdade termina (não o do
    // Component.onCompleted, só o pedido explícito pelo botão "Atualizar")
    // - a aba Plugins usa isso pra confirmar visualmente que a lista foi
    // atualizada de verdade, não só que o clique registrou.
    signal rescanFinished()

    Component.onCompleted: rescan()

    Process {
        id: scanProcess
        command: ["bash", root.scriptPath, root.pluginsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                let manifests = []
                try {
                    manifests = JSON.parse(this.text.trim() || "[]")
                } catch (e) {
                    manifests = []
                }
                root.plugins = manifests.map(m => Object.assign({}, m, {
                    enabled: root.isEnabled(m.id)
                }))
                root.rescanFinished()
            }
        }
    }

    // ---- Ligar/desligar por plugin, persistido em State/plugins-config.json ----
    // Formato array-de-objetos (não um mapa "{id: bool}") de propósito -
    // JsonAdapter já lida bem com isso (mesmo padrão comprovado em
    // NotificationService.qml "history"), diferente de um objeto com chaves
    // dinâmicas.

    function isEnabled(id) {
        const entry = enabledAdapter.overrides.find(o => o.id === id)
        return entry ? !!entry.enabled : true // ligado por padrão
    }

    function setEnabled(id, value) {
        const rest = enabledAdapter.overrides.filter(o => o.id !== id)
        enabledAdapter.overrides = [...rest, { id: id, enabled: value }]
        enabledFile.writeAdapter()
        root.plugins = root.plugins.map(p => p.id === id ? Object.assign({}, p, { enabled: value }) : p)
    }

    FileView {
        id: enabledFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/plugins-config.json"

        JsonAdapter {
            id: enabledAdapter
            property var overrides: []
        }
    }
}
