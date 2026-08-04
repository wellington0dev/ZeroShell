import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State

// Aba "Atalhos" das Configurações - troca as teclas das ações NOMEADAS de
// hypr/modules/keybindings.lua (ver State/KeybindConfig.qml pro porquê de
// só essas e não os binds estruturais tipo setas/workspaces/mouse) e permite
// criar atalhos personalizados que rodam um comando de shell qualquer.
//
// Cada atalho tem até 3 "caixas" de tecla - a 1a é sempre a tecla
// principal (mainMod, SUPER por padrão - mesma pra todos os atalhos, só
// editável na linha do topo), as outras 2 são por atalho. Clicar numa
// caixa começa a captura (a PRÓXIMA tecla pressionada preenche ela, uma
// de cada vez - não um combo inteiro de um toque só); nada é salvo até
// clicar "Salvar"/"Adicionar" na linha daquele atalho.
//
// A página inteira mora dentro de um Flickable só (mesmo padrão de
// WallpaperGrid.qml/ColorCustomizer.qml) em vez de ter uma lista com
// scroll próprio e o resto fixo - assim a seção de atalhos personalizados
// no final sempre fica alcançável rolando a página toda.
Item {
    id: root

    // Enquanto capturando: "capturingId" é o id da ação (ou "__mainMod__"
    // ou "__custom_new__", pro rascunho de atalho personalizado) e
    // "capturingSlot" é 0 (só existe uma caixa pro mainMod) ou 1/2 (a 2a/3a
    // caixa de um atalho normal - a 1a caixa de todo atalho é o mainMod,
    // fixo, não captura).
    property string capturingId: ""
    property int capturingSlot: -1

    // Só existe pra um delegate falar com outro (delegates de Repeater são
    // recriados, não dá pra guardar uma referência direta) - guarda a
    // edição em andamento de CADA atalho por id, não aplicada ainda (só o
    // clique em "Salvar" manda pra KeybindConfig de verdade).
    property var pendingById: ({})

    // Rascunho do novo atalho personalizado em construção (seção do final
    // da página) - só vira um customBind de verdade em KeybindConfig quando
    // "Adicionar" é clicado.
    property var newCustomKeys: ["", ""]
    property string newCustomCommand: ""

    readonly property var actions: [
        { id: "terminal", label: "Abrir terminal", defaultKeys: ["T"] },
        { id: "closeWindow", label: "Fechar janela", defaultKeys: ["Q"] },
        { id: "exitMenu", label: "Sair do Hyprland", defaultKeys: ["M"] },
        { id: "fileManager", label: "Gerenciador de arquivos", defaultKeys: ["E"] },
        { id: "floatToggle", label: "Flutuar janela", defaultKeys: ["V"] },
        { id: "menu", label: "Abrir launcher", defaultKeys: ["R"] },
        { id: "pseudo", label: "Pseudo-tile", defaultKeys: ["P"] },
        { id: "togglesplit", label: "Alternar divisão (dwindle)", defaultKeys: ["J"] },
        { id: "nextWallpaper", label: "Próximo wallpaper", defaultKeys: ["W"] },
        { id: "settings", label: "Abrir Configurações", defaultKeys: ["C"] },
        { id: "specialWorkspace", label: "Workspace especial", defaultKeys: ["S"] },
        { id: "screenshot", label: "Captura de tela", defaultKeys: ["SHIFT", "S"] },
        { id: "screenrecord", label: "Gravação de tela", defaultKeys: ["SHIFT", "G"] }
    ]

    function qtModifierKeyToHyprland(key) {
        if (key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R) return "SUPER"
        if (key === Qt.Key_Control) return "CTRL"
        if (key === Qt.Key_Shift) return "SHIFT"
        if (key === Qt.Key_Alt) return "ALT"
        return null
    }

    // Nomes de tecla no formato que o Hyprland espera (ver binds já
    // existentes em keybindings.lua: letras maiúsculas, dígitos crus,
    // setas em minúsculo). Cobre o que é razoável esperar num atalho -
    // não é exaustivo (Qt tem uns 100+ Key_*), mas cobre bem mais que os
    // 13 usados hoje, sobra espaço pra ação nova no futuro.
    function qtKeyToHyprland(key) {
        if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key)
        if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
        if (key >= Qt.Key_F1 && key <= Qt.Key_F12) return "F" + (key - Qt.Key_F1 + 1)
        const pairs = [
            [Qt.Key_Left, "left"], [Qt.Key_Right, "right"], [Qt.Key_Up, "up"], [Qt.Key_Down, "down"],
            [Qt.Key_Space, "space"], [Qt.Key_Tab, "Tab"], [Qt.Key_Escape, "Escape"],
            [Qt.Key_Return, "Return"], [Qt.Key_Enter, "Return"],
            [Qt.Key_Comma, "comma"], [Qt.Key_Period, "period"], [Qt.Key_Slash, "slash"],
            [Qt.Key_Backslash, "backslash"], [Qt.Key_Minus, "minus"], [Qt.Key_Equal, "equal"],
            [Qt.Key_BracketLeft, "bracketleft"], [Qt.Key_BracketRight, "bracketright"],
            [Qt.Key_Semicolon, "semicolon"], [Qt.Key_Apostrophe, "apostrophe"], [Qt.Key_QuoteLeft, "grave"],
            [Qt.Key_Backspace, "BackSpace"], [Qt.Key_Delete, "Delete"],
            [Qt.Key_Home, "Home"], [Qt.Key_End, "End"],
            [Qt.Key_PageUp, "Prior"], [Qt.Key_PageDown, "Next"],
            [Qt.Key_Insert, "Insert"]
        ]
        for (let i = 0; i < pairs.length; i++) {
            if (pairs[i][0] === key) return pairs[i][1]
        }
        return null
    }

    // Uma tecla só, seja ela um modificador sozinho (SHIFT/CTRL/ALT/SUPER)
    // ou uma tecla normal - ao contrário de um atalho "combo" de um toque
    // só, cada caixa aqui pega UMA tecla por vez (pedido explícito: "1 pra
    // cada tecla").
    function captureAnyKey(event) {
        const mod = root.qtModifierKeyToHyprland(event.key)
        if (mod) return mod
        return root.qtKeyToHyprland(event.key)
    }

    function startCapture(id, slot) {
        root.capturingId = id
        root.capturingSlot = slot
        captureTarget.forceActiveFocus()
    }

    function stopCapture() {
        root.capturingId = ""
        root.capturingSlot = -1
    }

    function keysFor(id, defaultKeys) {
        if (root.pendingById[id]) return root.pendingById[id]
        return KeybindConfig.getKeys(id, defaultKeys).slice()
    }

    function setPending(id, slot, keyName) {
        const current = root.keysFor(id, root.actions.find(a => a.id === id).defaultKeys).slice()
        while (current.length <= slot) current.push("")
        current[slot] = keyName
        const copy = Object.assign({}, root.pendingById)
        copy[id] = current
        root.pendingById = copy
    }

    function clearPending(id, slot) {
        root.setPending(id, slot, "")
    }

    function commitPending(id) {
        const keys = (root.pendingById[id] || []).filter(k => k.length > 0)
        KeybindConfig.setKeys(id, keys)
        const copy = Object.assign({}, root.pendingById)
        delete copy[id]
        root.pendingById = copy
    }

    // Item focável e invisível só pra capturar o próximo keyPressEvent
    // enquanto uma caixa está "armada" - nenhuma UI própria, só escuta.
    Item {
        id: captureTarget
        focus: root.capturingId !== ""

        Keys.onPressed: (event) => {
            if (root.capturingId === "") return

            if (event.key === Qt.Key_Escape) {
                root.stopCapture()
                event.accepted = true
                return
            }

            const keyName = root.captureAnyKey(event)
            if (!keyName) {
                event.accepted = true
                return
            }

            if (root.capturingId === "__mainMod__") {
                KeybindConfig.setMainMod(keyName)
            } else if (root.capturingId === "__custom_new__") {
                const keys = root.newCustomKeys.slice()
                keys[root.capturingSlot] = keyName
                root.newCustomKeys = keys
            } else {
                root.setPending(root.capturingId, root.capturingSlot, keyName)
            }
            root.stopCapture()
            event.accepted = true
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: flick.width
            spacing: Styles.spacing

            Text {
                text: "Atalhos"
                color: Styles.foreground
                font.pixelSize: 16
                font.family: Styles.fontFamily
                font.bold: true
            }

            Text {
                text: "Clique numa caixa de tecla pra gravar (uma tecla por vez, Esc cancela) e depois em \"Salvar\". Aplica na hora, sem precisar reiniciar o Hyprland."
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: mainModRow.implicitHeight + Styles.spacing * 2
                radius: Styles.radiusShell
                color: Styles.surface
                border.color: Styles.border
                border.width: 1

                RowLayout {
                    id: mainModRow
                    anchors.fill: parent
                    anchors.margins: Styles.spacing
                    spacing: Styles.spacing

                    Text {
                        text: "Tecla principal (mainMod)"
                        color: Styles.foreground
                        font.pixelSize: Styles.fontSizeSmall
                        font.family: Styles.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    KeyBox {
                        text: KeybindConfig.mainMod
                        capturing: root.capturingId === "__mainMod__"
                        onTapped: root.startCapture("__mainMod__", 0)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.actions

                    delegate: RowLayout {
                        id: actionRow

                        required property var modelData

                        // Sempre 2 caixas extras (índice 0 e 1) além do
                        // mainMod - vazia ("") quando aquele atalho só usa
                        // 1 tecla extra ou nenhuma.
                        readonly property var pendingKeys: {
                            root.pendingById // força reavaliar quando pendingById muda
                            const keys = root.keysFor(actionRow.modelData.id, actionRow.modelData.defaultKeys)
                            return [keys[0] || "", keys[1] || ""]
                        }
                        readonly property bool dirty: !!root.pendingById[actionRow.modelData.id]
                        readonly property bool overridden: KeybindConfig.overrides.some(o => o.id === actionRow.modelData.id)

                        Layout.fillWidth: true
                        spacing: Styles.spacing

                        Text {
                            text: actionRow.modelData.label
                            color: Styles.foreground
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                            Layout.fillWidth: true
                        }

                        // Caixa 1: sempre o mainMod, só mostra (não captura
                        // aqui - muda na linha do topo, vale pra todos os
                        // atalhos juntos).
                        KeyBox {
                            text: KeybindConfig.mainMod
                            fixed: true
                        }

                        Text {
                            text: "+"
                            color: Styles.foregroundMuted
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                        }

                        KeyBox {
                            text: actionRow.pendingKeys[0]
                            capturing: root.capturingId === actionRow.modelData.id && root.capturingSlot === 0
                            onTapped: root.startCapture(actionRow.modelData.id, 0)
                            onCleared: root.clearPending(actionRow.modelData.id, 0)
                        }

                        Text {
                            text: "+"
                            visible: actionRow.pendingKeys[0].length > 0
                            color: Styles.foregroundMuted
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                        }

                        KeyBox {
                            visible: actionRow.pendingKeys[0].length > 0
                            text: actionRow.pendingKeys[1]
                            capturing: root.capturingId === actionRow.modelData.id && root.capturingSlot === 1
                            onTapped: root.startCapture(actionRow.modelData.id, 1)
                            onCleared: root.clearPending(actionRow.modelData.id, 1)
                        }

                        IconButton {
                            visible: actionRow.overridden && !actionRow.dirty
                            icon: "restart"
                            size: 24
                            onClicked: KeybindConfig.resetKeys(actionRow.modelData.id)
                        }

                        Button {
                            id: saveBindButton
                            text: "Salvar"
                            primary: actionRow.dirty
                            enabled: actionRow.dirty
                            onClicked: {
                                root.commitPending(actionRow.modelData.id)
                                saveBindButton.flashSuccess()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: Styles.spacing
                Layout.bottomMargin: Styles.spacing
                color: Styles.border
            }

            Text {
                text: "Atalhos personalizados"
                color: Styles.foreground
                font.pixelSize: 14
                font.family: Styles.fontFamily
                font.bold: true
            }

            Text {
                text: "Roda um comando de terminal ao pressionar a combinação. Escolha até 2 teclas extras e escreva o comando."
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Styles.spacing / 2

                Repeater {
                    model: KeybindConfig.customBinds

                    delegate: RowLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Styles.spacing

                        KeyBox { text: KeybindConfig.mainMod; fixed: true }
                        Text { text: "+"; color: Styles.foregroundMuted; font.pixelSize: Styles.fontSizeSmall; font.family: Styles.fontFamily }
                        KeyBox { text: modelData.keys[0] || ""; fixed: true }
                        Text {
                            text: "+"
                            visible: (modelData.keys[1] || "").length > 0
                            color: Styles.foregroundMuted
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                        }
                        KeyBox {
                            visible: (modelData.keys[1] || "").length > 0
                            text: modelData.keys[1] || ""
                            fixed: true
                        }

                        Text {
                            text: modelData.command
                            color: Styles.foreground
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        IconButton {
                            icon: "close"
                            size: 24
                            onClicked: KeybindConfig.removeCustomBind(modelData.id)
                        }
                    }
                }

                Text {
                    visible: KeybindConfig.customBinds.length === 0
                    text: "Nenhum atalho personalizado ainda."
                    color: Styles.foregroundMuted
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Styles.spacing
                spacing: Styles.spacing

                KeyBox { text: KeybindConfig.mainMod; fixed: true }
                Text { text: "+"; color: Styles.foregroundMuted; font.pixelSize: Styles.fontSizeSmall; font.family: Styles.fontFamily }

                KeyBox {
                    text: root.newCustomKeys[0]
                    capturing: root.capturingId === "__custom_new__" && root.capturingSlot === 0
                    onTapped: root.startCapture("__custom_new__", 0)
                    onCleared: { const k = root.newCustomKeys.slice(); k[0] = ""; root.newCustomKeys = k }
                }

                Text {
                    text: "+"
                    visible: root.newCustomKeys[0].length > 0
                    color: Styles.foregroundMuted
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                }

                KeyBox {
                    visible: root.newCustomKeys[0].length > 0
                    text: root.newCustomKeys[1]
                    capturing: root.capturingId === "__custom_new__" && root.capturingSlot === 1
                    onTapped: root.startCapture("__custom_new__", 1)
                    onCleared: { const k = root.newCustomKeys.slice(); k[1] = ""; root.newCustomKeys = k }
                }

                TextField {
                    Layout.fillWidth: true
                    placeholder: "Comando (ex.: kitty --class scratchpad)"
                    text: root.newCustomCommand
                    onTextChanged: root.newCustomCommand = text
                }

                Button {
                    id: addBindButton
                    text: "Adicionar"
                    primary: root.newCustomCommand.length > 0
                    enabled: root.newCustomCommand.length > 0
                    onClicked: {
                        const keys = root.newCustomKeys.filter(k => k.length > 0)
                        KeybindConfig.addCustomBind(keys, root.newCustomCommand)
                        root.newCustomKeys = ["", ""]
                        root.newCustomCommand = ""
                        addBindButton.flashSuccess()
                    }
                }
            }
        }
    }
}
