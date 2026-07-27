pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

// Servidor de notificações compartilhado - antes vivia só dentro de
// NotificationPopups.qml, mas agora a aba "Início" do Dashboard também
// precisa da mesma lista (pra mostrar as recentes com opção de apagar), daí
// virar singleton. "tracked = true" faz o Quickshell manter a notificação em
// "trackedNotifications" até ela expirar ou ser dispensada - é essa lista
// que tanto os popups quanto o Dashboard leem.
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

        onNotification: (notif) => { notif.tracked = true }
    }

    readonly property var notifications: server.trackedNotifications.values
}
