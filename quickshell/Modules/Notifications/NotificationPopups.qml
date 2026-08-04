import QtQuick
import Quickshell
import qs.Theme
import qs.State

PanelWindow {
    id: root

    // "Notificações" desligado (Dashboard > aba Ajustes) só esconde os
    // POPUPS - o NotificationService continua registrando tudo em
    // "history" normalmente (aba Início do Dashboard), então nada se perde
    // enquanto tá "mudo", só não interrompe na hora.
    readonly property var notifications: QuickSettings.notificationsEnabled ? NotificationService.notifications : []

    // "visible" NÃO pode seguir "notifications.length > 0" direto: quando a
    // ÚLTIMA notificação é removida, isso zera na mesma hora que o "remove"
    // do ListView começa a animar - a PanelWindow fecha/destrói a
    // superfície NO MEIO da animação de saída, cortando o fade (e gerando
    // erro, já que a NumberAnimation perde o item que tava animando embaixo
    // dela). Com 2+ notificações isso nunca acontece (a janela continua
    // visível pelas que sobraram) - só reproduz removendo a última/única.
    // Fix: mantém a janela visível mais um pouco (closeDelay) depois da
    // lista esvaziar, tempo da transição "remove" terminar antes de
    // "visible" virar false de verdade.
    visible: notifications.length > 0 || closeDelay.running
    onNotificationsChanged: if (notifications.length === 0) closeDelay.restart()

    Timer { id: closeDelay; interval: 200 }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins {
        top: 16
        right: 16
    }

    implicitWidth: 340
    implicitHeight: list.implicitHeight

    ListView {
        id: list

        width: parent.width
        implicitHeight: contentHeight
        model: root.notifications
        spacing: Styles.spacing
        interactive: false

        // Entrada/saída (fade + slide) são responsabilidade do próprio
        // NotificationCard agora (ver comentário grande em
        // NotificationCard.qml sobre por que um "add:"/"remove:" aqui no
        // ListView nunca funcionava de verdade).
        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
            width: list.width
            notification: modelData
        }
    }
}
