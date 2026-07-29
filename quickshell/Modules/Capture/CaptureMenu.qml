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

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Component.onCompleted: {
        card.scale = 0.92
        card.opacity = 0
        Qt.callLater(() => { card.scale = 1; card.opacity = 1 })
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Visibility.captureMenuOpen = false
    }

    Shadow { target: card }

    Rectangle {
        id: card

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: 360
        height: 220
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
                text: "Captura de tela"
                color: Colors.foreground
                font.pixelSize: Colors.fontSizeLarge
                font.family: Colors.fontFamily
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Colors.spacing * 1.5

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
                Layout.topMargin: Colors.spacing
                spacing: Colors.spacing

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
