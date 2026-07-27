import QtQuick
import qs.Theme
import qs.Widgets
import qs.State

// Botão da sidebar pra captura de tela. Tem dois modos:
// - Parado: ícone de câmera, clique abre o CaptureMenu (escolher alvo e
//   ação, igual a um IconButton comum).
// - Gravando: ícone vira "stop" e fica com um pontinho vermelho pulsando (pra
//   ficar óbvio que tem uma gravação rolando em segundo plano); clique aqui
//   PARA a gravação direto, sem precisar abrir o menu de novo.
IconButton {
    id: root

    icon: CaptureService.recording ? "stop" : "camera"
    active: CaptureService.recording || Visibility.captureMenuOpen

    onClicked: {
        if (CaptureService.recording) {
            CaptureService.stopRecording()
        } else {
            Visibility.captureMenuOpen = !Visibility.captureMenuOpen
        }
    }

    Rectangle {
        visible: CaptureService.recording
        width: 8
        height: 8
        radius: 4
        color: Colors.danger
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 2

        SequentialAnimation on opacity {
            running: CaptureService.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 600 }
            NumberAnimation { to: 1; duration: 600 }
        }
    }
}
