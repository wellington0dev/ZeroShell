import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Theme
import qs.Widgets
import qs.State

// Menu de captura/gravação de tela: escolha o alvo (região/janela/tela
// cheia) e depois "Capturar" ou "Gravar". Modal centralizado, igual ao menu
// de energia e ao launcher.
//
// De propósito NÃO pedimos foco de teclado aqui ("focusable" fica de fora) -
// assim a janela que estava em foco antes de abrir o menu continua em foco,
// o que é essencial pro modo "Janela" capturar a janela certa (a que o
// usuário realmente quer, não o nosso próprio menu).
//
// IMPORTANTE: diferente dos outros painéis do shell (que só alternam
// "visible"), este é instanciado por um Loader em shell.qml que destrói o
// componente inteiro ao fechar. Motivo: logo depois de fechar, este menu
// dispara o slurp (outra superfície em tela cheia, pro modo "Região"/
// "Janela"). Se a nossa própria superfície layer-shell continuasse viva só
// com "visible: false", ela ficava disputando a superfície de tela cheia com
// o slurp - o slurp nunca recebia clique nenhum e travava esperando pra
// sempre. Destruir de verdade (via Loader) evita essa disputa.
PanelWindow {
    id: root

    property string selectedTarget: "region"

    // Esta janela é destruída de verdade ao fechar (Loader em shell.qml, ver
    // comentário acima) - não dá pra ligar o pop-in num "Visibility.xxxOpen"
    // que persiste entre aberturas, já que aqui SEMPRE é uma abertura nova.
    // Por isso "shown" começa false e um Timer vira true logo depois de
    // criada, dando o mesmo "estado fechado real por um frame" que os outros
    // painéis conseguem de graça (a property já existia antes com o valor
    // antigo). Timer em vez de Qt.callLater - testado ao vivo (Launcher,
    // mesmo padrão) que Qt.callLater roda rápido demais aqui e o Behavior
    // nunca chega a interpolar nada.
    property bool shown: false

    Timer { interval: 1; running: true; onTriggered: root.shown = true }

    // Tipo/velocidade da animação de abrir vêm de Configurações > Aparência
    // > Animações (Motion.animationType) - ver Widgets/PanelAnim.qml.
    PanelAnim {
        id: anim
        open: root.shown
        edge: "bottom"
        distance: card.height
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Visibility.captureMenuOpen = false
    }

    Shadow { target: card }

    Rectangle {
        id: card

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Styles.edgeMargin + anim.slideOffset
        anchors.horizontalCenter: parent.horizontalCenter
        width: 360
        height: 220
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
                text: "Captura de tela"
                color: Styles.foreground
                font.pixelSize: Styles.fontSizeLarge
                font.family: Styles.fontFamily
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Styles.spacing * 1.5

                TargetButton {
                    icon: "crop"
                    label: "Região"
                    selected: root.selectedTarget === "region"
                    onActivated: root.selectedTarget = "region"
                }

                TargetButton {
                    icon: "window"
                    label: "Janela"
                    selected: root.selectedTarget === "window"
                    onActivated: root.selectedTarget = "window"
                }

                TargetButton {
                    icon: "fullscreen"
                    label: "Tela cheia"
                    selected: root.selectedTarget === "fullscreen"
                    onActivated: root.selectedTarget = "fullscreen"
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Styles.spacing
                spacing: Styles.spacing

                Button {
                    text: "Capturar"
                    onClicked: {
                        CaptureService.requestScreenshot(root.selectedTarget)
                        Visibility.captureMenuOpen = false
                    }
                }

                Button {
                    text: CaptureService.recording
                        ? ("Parar (" + CaptureService.formatElapsed() + ")")
                        : "Gravar"
                    primary: !CaptureService.recording
                    onClicked: {
                        if (CaptureService.recording) {
                            CaptureService.stopRecording()
                        } else {
                            CaptureService.requestRecording(root.selectedTarget)
                        }
                        Visibility.captureMenuOpen = false
                    }
                }
            }
        }
    }
}
