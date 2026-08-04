import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Theme
import qs.Widgets
import qs.Modules.Power
import qs.State

// Lockscreen de verdade, via protocolo ext-session-lock do Wayland
// (WlSessionLock) - diferente dos outros painéis do shell (PanelWindow
// comuns, dispensáveis com Esc ou clique fora), isso realmente bloqueia a
// sessão inteira: nada mais recebe input enquanto "locked" for true, nem
// troca de janela nem outro painel. Senha conferida via PAM
// (hypr/scripts/lock-auth.py) - QML sozinho não tem como checar senha de
// sistema (/etc/shadow não é legível por usuário comum).
//
// Raiz é um Item comum, não o WlSessionLock direto: WlSessionLock tem
// "defaultProperty: surface" (só aceita UM Component ali, não uma lista de
// filhos como a maioria dos itens QML) - um FileView/IpcHandler declarado
// direto dentro dele nunca vira um objeto de verdade (visto ao vivo: "id
// not defined"). Por isso ficam aqui fora, como irmãos do WlSessionLock.
//
// IMPORTANTE: o IpcHandler abaixo só expõe "lock", nunca "unlock" - só o
// caminho da senha certa (dentro do Component da surface) pode destravar.
// Se "unlock" fosse exposto por IPC, qualquer processo local desbloquearia
// sem senha nenhuma.
Item {
    id: lockRoot

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string username: Quickshell.env("USER")
    readonly property string facePath: Quickshell.env("HOME") + "/.face"
    readonly property string wallpaperPath: (wallpaperPathFile.text() || "").trim()

    FileView {
        id: wallpaperPathFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
    }

    IpcHandler {
        target: "lockscreen"

        // Bound ao botão "Bloquear" do menu de energia
        // (Modules/Power/PowerMenu.qml).
        function lock(): void {
            sessionLock.locked = true
        }

        // DEBUG TEMPORÁRIO - rede de segurança pra testar sem digitar senha
        // de verdade (ydotool não é confiável nesta máquina). Remover antes
        // de considerar a feature pronta.
        function debugUnlock(): void {
            sessionLock.locked = false
        }
    }

    // Trava a sessão sozinha depois de 5min sem input (mouse/teclado) -
    // "timeout" é em SEGUNDOS (confirmado ao vivo: com timeout=5, isIdle
    // virava true exatos ~5.0s depois do quickshell subir, não 5000s).
    // "enabled: !QuickSettings.keepAwake" é o que faz o toggle "Manter
    // acordado" (Dashboard > aba Ajustes) também desligar o auto-lock, não
    // só o suspend/DPMS do sistema (ver IdleInhibitor em Sidebar.qml).
    IdleMonitor {
        id: idleMonitor
        timeout: 300
        enabled: !QuickSettings.keepAwake
        onIsIdleChanged: if (isIdle) sessionLock.locked = true
    }

    WlSessionLock {
        id: sessionLock

        surface: Component {
            WlSessionLockSurface {
                id: surfaceRoot

                property string password: ""
                property string errorText: ""
                property bool checking: false

                function tryUnlock() {
                    if (checking || password.length === 0) return
                    checking = true
                    errorText = ""
                    authProcess.running = true
                }

                Process {
                    id: authProcess
                    command: ["python3", lockRoot.scriptsDir + "/lock-auth.py", lockRoot.username]
                    stdinEnabled: true

                    onStarted: write(surfaceRoot.password + "\n")

                    onExited: (exitCode) => {
                        surfaceRoot.checking = false
                        if (exitCode === 0) {
                            sessionLock.locked = false
                        } else {
                            surfaceRoot.errorText = "Senha incorreta"
                            surfaceRoot.password = ""
                            passwordInput.text = ""
                            passwordInput.forceActiveFocus()
                        }
                    }
                }

                // Fundo: wallpaper desfocado cobrindo a tela toda. A Image
                // de verdade fica invisível - só existe como fonte pro
                // MultiEffect.
                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: lockRoot.wallpaperPath ? "file://" + lockRoot.wallpaperPath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: bgImage
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    autoPaddingEnabled: false
                }

                // Escurece um pouco por cima do blur - melhora contraste do
                // avatar/texto/input contra qualquer wallpaper.
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.25
                }

                ColumnLayout {
                    id: mainColumn

                    anchors.centerIn: parent
                    spacing: Styles.spacing * 1.5

                    // Wallpaper + avatar ficam FORA do card, flutuando sobre
                    // o blur - só usuário/input/erro ficam dentro do card
                    // (Styles.background). Item comum (não ColumnLayout)
                    // porque o avatar precisa SOBREPOR o wallpaper (50% da
                    // própria altura por cima dele, estilo banner de perfil)
                    // - um layout normal só empilha sem sobrepor.
                    Item {
                        id: banner

                        Layout.alignment: Qt.AlignHCenter
                        width: wallpaperThumb.width
                        height: wallpaperThumb.height + avatar.height / 2

                        // Miniatura do wallpaper: nítida (sem blur, ao
                        // contrário do fundo), com o próprio raio/borda do
                        // shell. +30% de tamanho em relação ao original
                        // (240x140 -> 312x182).
                        ClippingRectangle {
                            id: wallpaperThumb

                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 374
                            height: 218
                            radius: Styles.radiusShell
                            color: Styles.surfaceAlt
                            border.color: Styles.border
                            border.width: 2

                            Image {
                                anchors.fill: parent
                                source: lockRoot.wallpaperPath ? "file://" + lockRoot.wallpaperPath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        ClippingRectangle {
                            id: avatar

                            anchors.horizontalCenter: parent.horizontalCenter
                            y: wallpaperThumb.height - height / 2
                            width: 120
                            height: 120
                            radius: width / 2
                            color: Styles.surfaceAlt
                            border.color: Styles.border
                            border.width: 2

                            Image {
                                anchors.fill: parent
                                source: "file://" + lockRoot.facePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                        }
                    }

                    Rectangle {
                        id: unlockCard

                        Layout.alignment: Qt.AlignHCenter
                        width: 300
                        height: cardContent.implicitHeight + Styles.spacing * 3
                        radius: Styles.radiusShell
                        color: Styles.background
                        border.color: Styles.border
                        border.width: 2

                        ColumnLayout {
                            id: cardContent

                            anchors.fill: parent
                            anchors.margins: Styles.spacing * 1.5
                            spacing: Styles.spacing

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: lockRoot.username
                                color: Styles.foreground
                                font.pixelSize: Styles.fontSizeTitle
                                font.bold: true
                                font.family: Styles.fontFamily
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: Styles.radiusInput
                                color: Styles.surface
                                border.color: passwordInput.activeFocus ? Styles.accent : Styles.border
                                border.width: 1

                                Behavior on border.color {
                                    ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
                                }

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    color: Styles.foreground
                                    font.pixelSize: Styles.fontSizeNormal
                                    font.family: Styles.fontFamily
                                    echoMode: TextInput.Password
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    enabled: !surfaceRoot.checking
                                    focus: true

                                    onTextChanged: surfaceRoot.password = text
                                    onAccepted: surfaceRoot.tryUnlock()

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: surfaceRoot.checking ? "Verificando…" : "Senha"
                                        color: Styles.foregroundMuted
                                        font.pixelSize: Styles.fontSizeNormal
                                        font.family: Styles.fontFamily
                                        visible: passwordInput.text.length === 0
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: surfaceRoot.errorText.length > 0
                                text: surfaceRoot.errorText
                                color: Styles.danger
                                font.pixelSize: Styles.fontSizeSmall
                                font.family: Styles.fontFamily
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // Botão de energia - canto inferior-direito da tela, fora do
                // mainColumn. Abre o mesmo menu de "Sair/Suspender/Reiniciar/
                // Desligar" da PowerMenu.qml normal, só que embutido aqui: a
                // PowerMenu de verdade é uma janela comum, e a superfície de
                // sessão travada fica acima de TUDO por protocolo - nada
                // externo a este Component apareceria por cima dela.
                IconButton {
                    id: powerButton

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Styles.spacing * 2
                    icon: "shutdown"
                    size: 40
                    onClicked: powerPopup.visible = !powerPopup.visible
                }

                // Menu de energia embutido, à esquerda do botão.
                Rectangle {
                    id: powerPopup

                    visible: false
                    anchors.right: powerButton.left
                    anchors.bottom: powerButton.bottom
                    anchors.rightMargin: Styles.spacing * 1.5
                    width: 300
                    height: 120
                    radius: Styles.radiusShell
                    color: Styles.background
                    border.color: Styles.border
                    border.width: 2

                    Process { id: powerProc }
                    function runPower(cmd) {
                        powerProc.command = cmd
                        powerProc.running = true
                        powerPopup.visible = false
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Styles.spacing

                        PowerButton {
                            icon: "logout"
                            label: "Sair"
                            onActivated: powerPopup.runPower(["hyprshutdown"])
                        }

                        PowerButton {
                            icon: "suspend"
                            label: "Suspender"
                            onActivated: powerPopup.runPower(["systemctl", "suspend"])
                        }

                        PowerButton {
                            icon: "restart"
                            label: "Reiniciar"
                            needsConfirm: true
                            tint: Styles.danger
                            onActivated: powerPopup.runPower(["systemctl", "reboot"])
                        }

                        PowerButton {
                            icon: "shutdown"
                            label: "Desligar"
                            needsConfirm: true
                            tint: Styles.danger
                            onActivated: powerPopup.runPower(["systemctl", "poweroff"])
                        }
                    }
                }

                Component.onCompleted: passwordInput.forceActiveFocus()
            }
        }
    }
}
