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
        spacing: Colors.spacing * 1.5

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Colors.spacing

            ProfilePicture {
                Layout.alignment: Qt.AlignHCenter
                size: 72
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: Colors.foreground
                font.pixelSize: 32
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
        anchors.leftMargin: Colors.spacing * 2
        width: 1
        color: Colors.border
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: divider.right
        anchors.leftMargin: Colors.spacing * 2
        anchors.right: parent.right
        spacing: Colors.spacing

        Text {
            text: "Notificações"
            color: Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            font.bold: true
        }

        ListView {
            visible: NotificationService.notifications.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Colors.spacing
            model: NotificationService.notifications

            delegate: NotificationCard {
                width: ListView.view.width
                notification: modelData
            }
        }

        Text {
            visible: NotificationService.notifications.length === 0
            text: "Nenhuma notificação recente"
            color: Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
        }
    }
}
