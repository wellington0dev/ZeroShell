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
        radius: Colors.radiusSmall
        color: Colors.background
        border.color: Colors.border
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacing
            spacing: 20

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: HelenaClient.loggedIn && HelenaClient.user
                        ? ("Helena — " + HelenaClient.user.username)
                        : "Helena"
                    color: Colors.foreground
                    font.pixelSize: Colors.fontSizeLarge
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

            // Login / register form
            ColumnLayout {
                id: authForm

                property bool registerMode: false

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !HelenaClient.loggedIn
                spacing: Colors.spacing

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: authForm.registerMode ? "Criar conta" : "Entrar"
                    color: Colors.foreground
                    font.pixelSize: 25
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
                    horizontalAlignment: Text.AlignHCenter
                }

                ListView {
                    id: messageList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Colors.spacing
                    model: HelenaClient.messages

                    delegate: MessageBubble {
                        required property var modelData
                        width: messageList.width
                        message: modelData
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: HelenaClient.sendError.length > 0
                    text: HelenaClient.sendError
                    color: Colors.danger
                    font.pixelSize: Colors.fontSizeSmaller
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    Layout.leftMargin: Colors.spacing
                    Layout.rightMargin: Colors.spacing
                    spacing: 8

                    Rectangle {
                        id: inputBox

                        Layout.fillWidth: true
                        implicitHeight: Math.min(inputEdit.contentHeight + 20, 90)
                        radius: Colors.radiusMedium
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
                            anchors.fill: parent
                            anchors.margins: 10
                            contentWidth: width
                            contentHeight: inputEdit.height
                            clip: true
                            interactive: contentHeight > height

                            TextEdit {
                                id: inputEdit
                                width: parent.width
                                color: Colors.foreground
                                font.pixelSize: Colors.fontSizeNormal
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
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: Colors.radiusFull
                        color: Colors.accent
                        opacity: (!HelenaClient.sending && inputEdit.text.trim().length > 0) ? 1 : 0.5

                        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }

                        Icon {
                            anchors.centerIn: parent
                            icon: "send"
                            size: 16
                            tint: Colors.background
                        }

                        TapHandler { onTapped: root.sendCurrent() }
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
