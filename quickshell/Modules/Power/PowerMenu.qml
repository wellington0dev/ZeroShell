import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets
import qs.State

PanelWindow {
    id: root

    function run(cmd) {
        proc.command = cmd
        proc.running = true
        Visibility.powerMenuOpen = false
    }

    function close() {
        Visibility.powerMenuOpen = false
    }

    IpcHandler {
        target: "powermenu"

        // Sem keybind dedicado hoje (só clique na sidebar) - existe pra
        // scripts (ex.: hypr/scripts/debug-shell.sh) abrirem sem precisar
        // simular clique de mouse.
        function toggle(): void {
            Visibility.powerMenuOpen = !Visibility.powerMenuOpen
        }
        function open(): void { Visibility.powerMenuOpen = true }
        function close(): void { Visibility.powerMenuOpen = false }
    }

    Process { id: proc }

    visible: Visibility.powerMenuOpen
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Tipo/velocidade da animação de abrir/fechar vêm de
    // Configurações > Aparência > Animações (Motion.animationType) - ver
    // Widgets/PanelAnim.qml. Ligação declarativa direta com
    // Visibility.powerMenuOpen, não o reset manual + Qt.callLater de antes -
    // testado ao vivo (no Launcher, mesmo padrão) que essa versão manual não
    // chega a animar nada, só salta direto pro valor final.
    PanelAnim {
        id: anim
        open: Visibility.powerMenuOpen
        edge: "bottom"
        distance: card.height
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Shadow { target: card }

    Rectangle {
        id: card

        // Canto inferior-esquerdo, não centralizado - leftMargin maior
        // (Styles.sidebarClearance) pra não ficar embaixo da sidebar (56px
        // de largura + 10 de margem = ~66px ocupados ali).
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Styles.sidebarClearance
        anchors.bottomMargin: Styles.edgeMargin + anim.slideOffset
        width: 420
        height: 160
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        opacity: anim.targetOpacity
        scale: anim.targetScale
        transformOrigin: Item.Bottom

        // Mesma curva do slide do Dashboard (Motion.standard) - pedido pra
        // ficar igual em todos os painéis, não cada um com a sua.
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.boing
            }
        }
        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing * 2
            spacing: Styles.spacing * 1.5

            Text {
                text: "Menu de energia"
                color: Styles.foreground
                font.pixelSize: Styles.fontSizeLarge
                font.family: Styles.fontFamily
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Styles.spacing * 1.5

                PowerButton {
                    icon: "lock"
                    label: "Bloquear"
                    // "hyprlock" nem tá instalado nesta máquina - a
                    // lockscreen agora é a nossa mesma (Modules/Lock/
                    // LockScreen.qml), via IPC (WlSessionLock não é algo
                    // que dá pra referenciar direto de outro arquivo QML).
                    onActivated: root.run(["qs", "ipc", "call", "lockscreen", "lock"])
                }

                PowerButton {
                    icon: "logout"
                    label: "Sair"
                    onActivated: root.run(["hyprshutdown"])
                }

                PowerButton {
                    icon: "suspend"
                    label: "Suspender"
                    onActivated: root.run(["systemctl", "suspend"])
                }

                PowerButton {
                    icon: "restart"
                    label: "Reiniciar"
                    needsConfirm: true
                    tint: Styles.danger
                    onActivated: root.run(["systemctl", "reboot"])
                }

                PowerButton {
                    icon: "shutdown"
                    label: "Desligar"
                    needsConfirm: true
                    tint: Styles.danger
                    onActivated: root.run(["systemctl", "poweroff"])
                }
            }
        }
    }
}
