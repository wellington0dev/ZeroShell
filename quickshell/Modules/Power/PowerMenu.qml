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

    onVisibleChanged: {
        if (visible) {
            card.scale = 0.92
            card.opacity = 0
            Qt.callLater(() => { card.scale = 1; card.opacity = 1 })
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Shadow { target: card }

    Rectangle {
        id: card

        // Canto inferior-esquerdo, não centralizado - leftMargin de 76 (não
        // um valor pequeno) pra não ficar embaixo da sidebar (56px de
        // largura + 10 de margem = ~66px ocupados ali), mesmo raciocínio de
        // HelenaWindow.qml.
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 76
        anchors.bottomMargin: 20
        width: 420
        height: 160
        radius: Colors.radiusShell
        color: Colors.background
        border.color: Colors.border
        border.width: 2

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
            anchors.margins: Colors.spacing * 2
            spacing: Colors.spacing * 1.5

            Text {
                text: "Menu de energia"
                color: Colors.foreground
                font.pixelSize: Colors.fontSizeLarge
                font.family: Colors.fontFamily
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Colors.spacing * 1.5

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
                    tint: Colors.danger
                    onActivated: root.run(["systemctl", "reboot"])
                }

                PowerButton {
                    icon: "shutdown"
                    label: "Desligar"
                    needsConfirm: true
                    tint: Colors.danger
                    onActivated: root.run(["systemctl", "poweroff"])
                }
            }
        }
    }
}
