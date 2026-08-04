pragma Singleton

import Quickshell
import Quickshell.Io

// Atalhos de teclado configuráveis - editável em Configurações > aba
// "Atalhos" (Modules/Settings/KeybindsPage.qml). Persistido em
// State/keybinds.json (mesmo padrão de SidebarConfig.qml/DockConfig.qml).
//
// Só cobre as ações NOMEADAS de hypr/modules/keybindings.lua (abrir
// terminal, fechar janela, etc - ver "actions" em KeybindsPage.qml pra
// lista completa) - binds estruturais (setas de foco/mover janela,
// workspaces 1-9-0, arrasto de mouse, teclas de mídia XF86) continuam
// fixos no próprio keybindings.lua, não fazem parte deste sistema.
//
// Cada ação usa "mainMod" (abaixo, um modificador só - SUPER por padrão)
// + até 2 teclas extras (guardadas em "overrides"), pra um total de até 3
// teclas por atalho. keybindings.lua não lê este JSON diretamente (Lua não
// tem parser de JSON embutido) - hypr/scripts/sync-hypr-keybinds.sh
// converte pra hypr/keybinds.lua (return { ... }, mesma técnica de
// theme_colors.lua/sync-hypr-colors.sh) toda vez que algo muda aqui, e já
// chama "hyprctl reload" na sequência.
Singleton {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    property string mainMod: adapter.mainMod
    property var overrides: adapter.overrides

    // Atalhos personalizados criados pelo usuário na aba - cada um roda um
    // comando de shell arbitrário (hl.dsp.exec_cmd), sem corresponder a
    // nenhuma ação nomeada de keybindings.lua. Mesma convenção das outras:
    // mainMod (global, acima) + até 2 teclas extras. "id" é gerado na
    // criação (Date.now()), só serve pra identificar a entrada na lista/
    // remover depois - não tem relação com as ações fixas.
    property var customBinds: adapter.customBinds

    function addCustomBind(keys, command) {
        const id = "custom_" + Date.now()
        adapter.customBinds = [...adapter.customBinds, { id: id, keys: keys, command: command }]
        file.writeAdapter()
        root.sync()
    }

    function removeCustomBind(id) {
        adapter.customBinds = adapter.customBinds.filter(b => b.id !== id)
        file.writeAdapter()
        root.sync()
    }

    // "defaultKeys" é a combinação ATUAL hardcoded em keybindings.lua (ex.:
    // ["T"] pro terminal, ["SHIFT", "S"] pra captura) - sem override salvo
    // ainda, é isso que continua valendo tanto aqui (pra mostrar na aba)
    // quanto no lado Lua (mesmo fallback nos dois lados, de propósito).
    function getKeys(id, defaultKeys) {
        const entry = root.overrides.find(o => o.id === id)
        return entry ? entry.keys : defaultKeys
    }

    function setKeys(id, keys) {
        const rest = adapter.overrides.filter(o => o.id !== id)
        adapter.overrides = [...rest, { id: id, keys: keys }]
        file.writeAdapter()
        root.sync()
    }

    // Remove o override (não é o mesmo que "setKeys(id, defaultKeys)" -
    // aquilo salvaria o default como override de qualquer jeito; isto tira
    // a entrada de vez, voltando a cair no default hardcoded dos dois
    // lados sozinho).
    function resetKeys(id) {
        adapter.overrides = adapter.overrides.filter(o => o.id !== id)
        file.writeAdapter()
        root.sync()
    }

    function setMainMod(value) {
        adapter.mainMod = value
        file.writeAdapter()
        root.sync()
    }

    function sync() {
        syncProcess.running = true
    }

    Process {
        id: syncProcess
        command: ["bash", root.scriptsDir + "/sync-hypr-keybinds.sh"]
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/keybinds.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string mainMod: "SUPER"
            property var overrides: []
            property var customBinds: []
        }
    }
}
