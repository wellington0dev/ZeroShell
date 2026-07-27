import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Theme
import qs.Widgets
import qs.State

// Janela de chat de voz da Helena: só um botão redondo de microfone. Um
// toque começa a gravar, o próximo para e manda o áudio (ver
// VoiceService.qml). É uma FloatingWindow de verdade (não layer-shell) pra
// poder ser arrastada com SUPER + clique-esquerdo, como qualquer outra
// janela flutuante do Hyprland - não tem lógica de arrastar própria de
// propósito, pra manter simples.
FloatingWindow {
    id: root

    title: "Helena Voz"
    visible: Visibility.voiceOpen
    color: Colors.background

    implicitWidth: 220
    implicitHeight: 260
    minimumSize: Qt.size(220, 260)

    onClosed: Visibility.voiceOpen = false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacing * 2
        spacing: Colors.spacing * 1.5

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Chat de voz"
                color: Colors.foreground
                font.pixelSize: Colors.fontSizeLarge
                font.bold: true
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                onClicked: Visibility.voiceOpen = false
            }
        }

        Item { Layout.fillHeight: true }

        // Botão redondo do microfone - muda de cor conforme o estado
        // (parado / gravando / processando / falando).
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 84
            height: 84
            radius: width / 2
            color: VoiceService.recording
                ? Colors.danger
                : (hover.hovered ? Colors.surfaceAlt : Colors.surface)
            border.color: VoiceService.recording ? Colors.danger : Colors.border
            border.width: 2
            opacity: VoiceService.processing ? 0.6 : 1

            Behavior on color { ColorAnimation { duration: Motion.durationFast } }

            // Pulso simples enquanto grava, só pra dar feedback de "tá vivo".
            SequentialAnimation on scale {
                running: VoiceService.recording
                loops: Animation.Infinite
                NumberAnimation { to: 1.08; duration: Motion.durationSlow; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: Motion.durationSlow; easing.type: Easing.InOutSine }
            }
            onScaleChanged: if (!VoiceService.recording) scale = 1.0

            Icon {
                anchors.centerIn: parent
                icon: "mic"
                size: 32
                tint: VoiceService.recording ? Colors.background : Colors.foreground
            }

            HoverHandler { id: hover; enabled: !VoiceService.processing }
            TapHandler {
                enabled: !VoiceService.processing
                onTapped: VoiceService.toggle()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: VoiceService.statusText
            color: VoiceService.errorText ? Colors.danger : Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
