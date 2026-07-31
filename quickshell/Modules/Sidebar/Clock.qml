import QtQuick
import Quickshell
import qs.Theme

// Relógio da sidebar: hora em negrito em cima, minutos menor embaixo.
//
// "SystemClock" é o tipo do Quickshell pra hora do sistema - evita ter que
// criar um Timer manual de 1 em 1 minuto. "precision: Minutes" já diz pro
// Quickshell não notificar mudanças mais frequentes que isso (não faria
// diferença mostrar segundos aqui de qualquer forma).
Column {
    id: root

    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Largura fixa (32) + texto centralizado em vez de deixar o Column
    // centralizar sozinho: garante que a hora e os minutos fiquem alinhados
    // um embaixo do outro mesmo quando os dígitos têm larguras diferentes.
    Text {
        width: 32
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, "hh")
        color: Styles.foreground
        font.pixelSize: 15
        font.family: Styles.fontFamily
        font.bold: true
    }

    Text {
        width: 32
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, "mm")
        color: Styles.foregroundMuted
        font.pixelSize: 12
        font.family: Styles.fontFamily
    }
}
