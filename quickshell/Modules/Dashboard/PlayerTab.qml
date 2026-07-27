import QtQuick
import QtQuick.Layouts
import qs.Modules.Player

// Aba "Player" do Dashboard: só embute o PlayerContent (extraído do antigo
// PlayerWindow.qml, que era uma janela própria acionada pela sidebar - agora
// mora aqui).
ColumnLayout {
    id: root

    PlayerContent {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Item { Layout.fillHeight: true }
}
