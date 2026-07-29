pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Servidor de notificações compartilhado - antes vivia só dentro de
// NotificationPopups.qml, mas agora a aba "Início" do Dashboard também
// precisa da mesma lista, daí virar singleton. "tracked = true" faz o
// Quickshell manter a notificação em "trackedNotifications" até ela expirar
// ou ser dispensada - é essa lista ("notifications" abaixo) que os popups
// leem (NotificationPopups.qml).
//
// O Dashboard (HomeTab.qml) NÃO usa "notifications" - usa "history" abaixo,
// persistido em State/notification-history.json. Motivo: só existe UM
// objeto Notification por notificação, compartilhado entre popup e
// Dashboard; o popup expira ele sozinho depois de alguns segundos
// (NotificationCard.qml), e esse expire() também sumia com o item na lista
// do Dashboard antes de alguém conseguir abrir o painel pra ver - a lista
// "funcionava" no sentido de popular, só que já estava vazia nos primeiros
// segundos depois. "history" guarda uma cópia simples dos dados (não o
// objeto Notification ao vivo), então sobrevive ao expire()/dismiss() do
// popup e ao próprio quickshell reiniciar; só sai daqui via
// removeFromHistory (botão de fechar de cada card) ou clearHistory (botão
// "Limpar" da aba Início).
Singleton {
    id: root

    NotificationServer {
        id: server

        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false

        onNotification: (notif) => {
            notif.tracked = true
            // Cópia rasa dos campos usados por NotificationCard.qml - não o
            // objeto "notif" em si, que pode ser destruído quando o popup
            // expira. Sem ações: uma notificação já expirada/histórica não
            // tem mais como invocar a ação de volta no app que a enviou.
            historyAdapter.history = [{
                id: notif.id,
                appName: notif.appName,
                appIcon: notif.appIcon,
                summary: notif.summary,
                body: notif.body,
                image: notif.image,
                urgency: notif.urgency,
                actions: [],
            }, ...historyAdapter.history].slice(0, 50)
            historyFile.writeAdapter()
        }
    }

    readonly property var notifications: server.trackedNotifications.values

    readonly property var history: historyAdapter.history

    function removeFromHistory(id) {
        historyAdapter.history = historyAdapter.history.filter(n => n.id !== id)
        historyFile.writeAdapter()
    }

    function clearHistory() {
        historyAdapter.history = []
        historyFile.writeAdapter()
    }

    // Sem "watchChanges"/"onFileChanged: reload()" de propósito: ninguém além
    // deste singleton escreve nesse arquivo, e reagir à própria escrita
    // causava um loop que MESCLAVA em vez de substituir o array "history" a
    // cada writeAdapter() - cada notificação nova duplicava as antigas.
    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/notification-history.json"

        JsonAdapter {
            id: historyAdapter
            property var history: []
        }
    }
}
