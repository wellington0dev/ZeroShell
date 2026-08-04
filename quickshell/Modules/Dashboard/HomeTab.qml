import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Theme
import qs.Widgets
import qs.Modules.Sidebar
import qs.Modules.Notifications

// Aba "Início" do Dashboard: coluna da esquerda com foto de perfil grande +
// horário + calendário do mês (hoje marcado); coluna da direita com as
// notificações recentes (reaproveita o mesmo NotificationCard dos popups -
// já tem botão de fechar, que aqui vira "apagar").
//
// Raiz é um Item simples com anchors em vez de RowLayout: um RowLayout aqui
// não estava distribuindo o espaço extra (Layout.fillWidth) pra coluna da
// direita corretamente - a folga inteira sumia num gap entre as colunas em
// vez de ir pro fillWidth. Com anchors a largura de cada coluna fica
// explícita e previsível.
Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: leftColumn

        anchors.top: parent.top
        anchors.left: parent.left
        width: 260
        spacing: Styles.spacing * 1.5

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Styles.spacing

            ProfilePicture {
                Layout.alignment: Qt.AlignHCenter
                size: 72
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: Styles.foreground
                font.pixelSize: 32
                font.family: Styles.fontFamily
                font.bold: true
            }
        }

        MiniCalendar { Layout.alignment: Qt.AlignHCenter }
    }

    Rectangle {
        id: divider

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftColumn.right
        anchors.leftMargin: Styles.spacing * 2
        width: 1
        color: Styles.border
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: divider.right
        anchors.leftMargin: Styles.spacing * 2
        anchors.right: parent.right
        spacing: Styles.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Text {
                text: "Notificações"
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                text: "Limpar"
                primary: false
                visible: NotificationService.history.length > 0
                onClicked: NotificationService.clearHistory()
            }
        }

        ListView {
            id: historyList

            // Mesmo motivo do "closeDelay" em NotificationPopups.qml: se
            // "visible" seguisse "length > 0" direto, apagar o ÚLTIMO item
            // escondia a lista inteira NO MEIO da animação de remoção
            // abaixo, cortando o fade/slide antes de terminar.
            visible: NotificationService.history.length > 0 || hideDelay.running
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Styles.spacing
            model: NotificationService.history

            Timer { id: hideDelay; interval: 200 }

            Connections {
                target: NotificationService
                function onHistoryChanged() {
                    if (NotificationService.history.length === 0) hideDelay.restart()
                }
            }

            // Entrada/saída (fade + slide) são responsabilidade do próprio
            // NotificationCard agora (ver comentário grande em
            // NotificationCard.qml sobre por que um "add:"/"remove:" aqui
            // no ListView nunca funcionava de verdade).
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
            }

            delegate: NotificationCard {
                width: ListView.view.width
                notification: modelData
                isPopup: false
            }
        }

        Text {
            // "!historyList.visible", não "length === 0" direto - fica
            // mutuamente exclusivo com a lista mesmo durante o hideDelay
            // dela (ver comentário lá em cima), senão os dois ficavam
            // visíveis ao mesmo tempo por ~200ms quando o último item é
            // removido.
            visible: !historyList.visible
            text: "Nenhuma notificação recente"
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
        }
    }
}
