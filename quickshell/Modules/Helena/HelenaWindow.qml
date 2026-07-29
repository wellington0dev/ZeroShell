import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets
import qs.State

PanelWindow {
    id: root

    IpcHandler {
        target: "helena"

        // Bound ao keybind SUPER+H no hyprland.lua:
        // qs ipc call helena toggle
        function toggle(): void {
            Visibility.helenaOpen = !Visibility.helenaOpen
        }
        // open/close explícitos (além do toggle acima) - scripts que
        // precisam de estado determinístico (ex.: debug-shell.sh) não podem
        // usar um toggle cego sem saber o estado atual antes.
        function open(): void { Visibility.helenaOpen = true }
        function close(): void { Visibility.helenaOpen = false }
    }

    visible: Visibility.helenaOpen
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
    }

    margins {
        top: Visibility.helenaOpen ? 30 : -(implicitHeight + 40)
        left: 76
    }

    Behavior on margins.top {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    implicitWidth: 320
    implicitHeight: 480

    onVisibleChanged: {
        if (visible) {
            HelenaClient.checkServer()
            Qt.callLater(() => {
                if (HelenaClient.loggedIn) inputEdit.forceActiveFocus()
                else usernameField.input.forceActiveFocus()
            })
        }
    }

    Connections {
        target: HelenaClient
        function onMessagesChanged() {
            Qt.callLater(() => messageList.positionViewAtEnd())
        }
    }

    Shadow { target: bg }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Colors.radiusShell
        color: Colors.background
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.6)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacing
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: Colors.radiusFull
                        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)

                        Icon {
                            anchors.centerIn: parent
                            icon: "chat"
                            size: 16
                            tint: Colors.accent
                        }
                    }

                    Text {
                        text: HelenaClient.loggedIn && HelenaClient.user
                            ? ("Helena — " + HelenaClient.user.username)
                            : "Helena"
                        color: Colors.foreground
                        font.pixelSize: Colors.fontSizeLarge
                        font.family: Colors.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Sair"
                        primary: false
                        visible: HelenaClient.loggedIn
                        onClicked: HelenaClient.logout()
                    }

                    IconButton {
                        icon: "close"
                        size: 24
                        onClicked: Visibility.helenaOpen = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.border
                    opacity: 0.6
                }
            }

            // Servidor fora do ar E deslogado: substitui a tela de login
            // inteira (não faz sentido deixar digitar usuário/senha contra
            // um servidor que não existe) por uma tela dedicada, com jeito
            // de resolver na hora - copiar o link do repo ou tentar de novo
            // sem precisar fechar/reabrir o painel.
            ColumnLayout {
                id: offlineView

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: HelenaClient.serverUnreachable && !HelenaClient.loggedIn
                spacing: Colors.spacing * 1.5

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: Colors.radiusFull
                    color: Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.18)

                    Icon {
                        anchors.centerIn: parent
                        icon: "close"
                        size: 26
                        tint: Colors.danger
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "Helena não está instalada ou não está rodando"
                    color: Colors.foreground
                    font.pixelSize: Colors.fontSizeLarge
                    font.bold: true
                    font.family: Colors.fontFamily
                    wrapMode: Text.Wrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "Não consegui falar com ela em " + HelenaClient.baseUrl + ". " +
                          "Clone o repositório e rode 'helena setup' + 'helena start'."
                    color: Colors.foregroundMuted
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontFamily
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Colors.spacing

                    Process {
                        id: copyLinkProcess
                        command: ["bash", "-c", "printf '%s' '" + HelenaClient.repoUrl + "' | wl-copy"]
                    }

                    Timer {
                        id: copiedResetTimer
                        interval: 1500
                        onTriggered: copyButton.copied = false
                    }

                    Button {
                        id: copyButton
                        property bool copied: false
                        text: copied ? "Copiado!" : "Copiar link"
                        onClicked: {
                            copyLinkProcess.running = true
                            copied = true
                            copiedResetTimer.restart()
                        }
                    }

                    Button {
                        text: "Tentar de novo"
                        primary: false
                        onClicked: HelenaClient.checkServer()
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Servidor fora do ar mas já logado (sessão salva de antes): não
            // bloqueia o histórico já carregado, só avisa - enviar mensagem
            // nova já mostra o próprio erro (sendError) na hora de tentar.
            Text {
                Layout.fillWidth: true
                visible: HelenaClient.serverUnreachable && HelenaClient.loggedIn
                text: "Não consegui falar com a Helena em " + HelenaClient.baseUrl + " agora."
                color: Colors.danger
                font.pixelSize: Colors.fontSizeSmaller
                font.family: Colors.fontFamily
                wrapMode: Text.Wrap
            }

            // Login / register form
            ColumnLayout {
                id: authForm

                property bool registerMode: false

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !HelenaClient.loggedIn && !HelenaClient.serverUnreachable
                spacing: Colors.spacing

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: authForm.registerMode ? "Criar conta" : "Entrar"
                    color: Colors.foreground
                    font.pixelSize: 25
                    font.family: Colors.fontFamily
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: usernameField
                    Layout.fillWidth: true
                    Layout.leftMargin:20
                    Layout.rightMargin:20
                    placeholder: "usuário"
                    onAccepted: passwordField.input.forceActiveFocus()
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.leftMargin:20
                    Layout.rightMargin:20
                    placeholder: "senha (mín. 6 caracteres)"
                    passwordMode: true
                    onAccepted: authButton.trigger()
                }

                Text {
                    Layout.fillWidth: true
                    visible: HelenaClient.loginError.length > 0
                    text: HelenaClient.loginError
                    color: Colors.danger
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontFamily
                    wrapMode: Text.Wrap
                }

                Button {
                    id: authButton
                    Layout.alignment: Qt.AlignHCenter
                    text: HelenaClient.loggingIn
                        ? (authForm.registerMode ? "Criando…" : "Entrando…")
                        : (authForm.registerMode ? "Criar conta" : "Entrar")
                    enabled: !HelenaClient.loggingIn
                    function trigger() {
                        if (!usernameField.text || !passwordField.text) return
                        if (authForm.registerMode) {
                            HelenaClient.register(usernameField.text, passwordField.text)
                        } else {
                            HelenaClient.login(usernameField.text, passwordField.text)
                        }
                    }
                    onClicked: trigger()
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: authForm.registerMode ? "Já tem conta? Entrar" : "Não tem conta? Cadastre-se"
                    color: Colors.foregroundMuted
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontFamily
                    font.underline: linkHover.hovered

                    HoverHandler { id: linkHover }
                    TapHandler {
                        onTapped: {
                            authForm.registerMode = !authForm.registerMode
                            HelenaClient.loginError = ""
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Chat
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: HelenaClient.loggedIn
                spacing: Colors.spacing

                Text {
                    Layout.fillWidth: true
                    visible: HelenaClient.loadingHistory
                    text: "Carregando…"
                    color: Colors.foregroundMuted
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: messageList
                        anchors.fill: parent
                        clip: true
                        spacing: Colors.spacing
                        model: HelenaClient.messages

                        delegate: MessageBubble {
                            required property var modelData
                            width: messageList.width
                            message: modelData
                        }

                        add: Transition {
                            NumberAnimation {
                                properties: "opacity"
                                from: 0
                                to: 1
                                duration: Motion.durationNormal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedDecel
                            }
                            NumberAnimation {
                                properties: "y"
                                duration: Motion.durationNormal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedDecel
                            }
                        }
                        displaced: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: Motion.durationFast
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standard
                            }
                        }
                    }

                    // Esmaece o topo da lista por baixo do cabeçalho, em vez de
                    // cortar mensagens de forma abrupta ao rolar.
                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 14
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Colors.background }
                            GradientStop { position: 1.0; color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0) }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: HelenaClient.sendError.length > 0
                    text: HelenaClient.sendError
                    color: Colors.danger
                    font.pixelSize: Colors.fontSizeSmaller
                    font.family: Colors.fontFamily
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    id: inputBox

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    Layout.leftMargin: Colors.spacing
                    Layout.rightMargin: Colors.spacing
                    implicitHeight: Math.min(inputEdit.contentHeight + 24, 96)
                    radius: Colors.radiusInput
                    color: Colors.surface
                    border.color: inputEdit.activeFocus ? Colors.accent : Colors.border
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Motion.durationFast } }
                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standard
                        }
                    }

                    Flickable {
                        anchors {
                            left: parent.left
                            right: sendButton.left
                            top: parent.top
                            bottom: parent.bottom
                            leftMargin: 12
                            rightMargin: 6
                            topMargin: 11
                            bottomMargin: 11
                        }
                        contentWidth: width
                        contentHeight: inputEdit.height
                        clip: true
                        interactive: contentHeight > height

                        TextEdit {
                            id: inputEdit
                            width: parent.width
                            color: Colors.foreground
                            font.pixelSize: Colors.fontSizeNormal
                            font.family: Colors.fontFamily
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true

                            Text {
                                text: HelenaClient.sending ? "enviando…" : "Mensagem… (Shift+Enter p/ nova linha)"
                                color: Colors.foregroundMuted
                                font: inputEdit.font
                                visible: inputEdit.text.length === 0
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Keys.onPressed: (event) => {
                                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                        && !(event.modifiers & Qt.ShiftModifier)) {
                                    event.accepted = true
                                    root.sendCurrent()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: sendButton
                        width: 30
                        height: 30
                        radius: Colors.radiusFull
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: 7
                        }
                        color: Colors.accent
                        opacity: (!HelenaClient.sending && inputEdit.text.trim().length > 0) ? 1 : 0.5
                        scale: sendTap.pressed ? 0.9 : 1

                        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.durationFast
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standard
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            icon: "send"
                            size: 14
                            tint: Colors.background
                        }

                        TapHandler { id: sendTap; onTapped: root.sendCurrent() }
                    }
                }
            }
        }
    }

    function sendCurrent() {
        if (!inputEdit.text.trim() || HelenaClient.sending) return
        HelenaClient.sendMessage(inputEdit.text)
        inputEdit.text = ""
    }
}
