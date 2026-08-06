import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    // "anim.shouldBeVisible" (NUNCA "Visibility.powerMenuOpen" direto) -
    // evita desmapear a superfície ANTES do slide terminar - ver comentário
    // em Widgets/PanelAnim.qml.
    visible: anim.shouldBeVisible

    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Enquanto genuinamente aberto, a máscara cobre a JANELA INTEIRA
    // (acompanha "clickOutside" abaixo) - precisa disso pro "clique fora
    // fecha o menu" (MouseArea de baixo) continuar funcionando em
    // qualquer ponto da tela. Só na cauda de fechamento (Visibility.
    // powerMenuOpen já é false mas "shouldBeVisible" ainda segura a
    // superfície viva pro slide terminar - ver Widgets/PanelAnim.qml)
    // encolhe pra só "card": nesse momento não precisamos mais detectar
    // clique-fora (já tá fechando), e uma superfície tela-inteira ainda
    // mapeada não pode ficar roubando clique de mais nada por baixo.
    mask: Region { item: Visibility.powerMenuOpen ? clickOutside : card }

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
        id: clickOutside
        anchors.fill: parent
        onClicked: root.close()
    }

    // Vão até a sidebar - "56" é a largura visual dela (Sidebar.qml,
    // shellWidth) + a margem de sempre que a separa das outras janelas
    // (Sidebar.qml, outerGapH), pra não ficar embaixo dela.
    readonly property int sidebarRightEdge: 56 + 10
    readonly property int leftClearance: sidebarRightEdge + Styles.edgeMargin

    Shadow { target: card }

    Rectangle {
        id: card

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.leftClearance
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
        // durationNormal (não durationFast) de propósito - mesma duração do
        // slide (anchors.bottomMargin, também durationNormal): sincronizado
        // assim, senão a opacidade chegava a 0 antes do slide terminar e o
        // card sumia (fade) bem antes de acabar de deslizar pra fora - a
        // segunda metade do movimento ficava invisível, sem ninguém ver.
        Behavior on opacity { NumberAnimation { duration: Motion.durationNormal } }

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
