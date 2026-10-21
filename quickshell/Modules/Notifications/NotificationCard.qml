import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.Theme
import qs.Widgets

// Card de notificação - usado em DOIS lugares:
//   - NotificationPopups.qml (isPopup: true)  : notificação viva, tem timeout
//   - Dashboard/HomeTab.qml   (isPopup: false) : histórico persistido, NÃO expira
//
// Redesenho de apresentação (Fase 2 da migração Rumda → ZeroShell). A
// referência foi ~/.config/rumda/common/quickshell/dark/widgets/Notifications.qml,
// mas ADAPTADA à arquitetura do ZeroShell: tokens de Theme/Styles.qml +
// Theme/Motion.qml, componentes de qs.Widgets, e sem trazer dependências do
// Rumda (que usaria Qt5Compat.GraphicalEffects e um NotificationServer
// próprio - aqui o servidor continua sendo o NotificationService singleton,
// único no shell).
Rectangle {
    id: root

    // "var", não "Notification": no popup é o objeto Notification ao vivo,
    // mas no histórico do Dashboard (isPopup: false) é uma cópia simples dos
    // dados (ver NotificationService.qml) - um tipo QML forte rejeitaria essa
    // segunda forma.
    property var notification

    // false na lista do Dashboard (HomeTab.qml): ali o card representa
    // histórico persistente, não deve sumir sozinho enquanto ninguém olha -
    // só nos popups (NotificationPopups.qml) o timeout deve valer.
    property bool isPopup: true

    readonly property int urgency: notification ? notification.urgency : NotificationUrgency.Normal
    readonly property color urgencyColor: urgency === NotificationUrgency.Critical ? Styles.danger : Styles.accent
    readonly property bool autoExpires: root.isPopup && urgency !== NotificationUrgency.Critical
    readonly property int timeoutMs: notification && notification.expireTimeout > 0
        ? notification.expireTimeout * 1000
        : 5000

    // ---- Geometria ----
    // Antes these dois números eram fixos (340 / card inteiro). Agora a barra
    // de progresso tem área RESERVADA no fim do card (como no Rumda, onde a
    // altura soma "notifBarTopMargin + notifBarHeight"), em vez de ficar
    // desenhada por cima do texto - com o card mais baixo que antes isso
    // invadia a mensagem.
    readonly property int barHeight: 3
    readonly property int barGap: 6
    readonly property int cardPadding: 12

    width: 340
    implicitHeight: content.implicitHeight + cardPadding * 2
        + (root.autoExpires ? root.barHeight + root.barGap : 0)
    radius: Styles.radiusShell
    color: Styles.surface
    border.width: 1
    clip: true

    // notification.image comes pre-resolved from Quickshell (file:// path or an
    // image:// provider URL for pixmap/theme-name data) - use it as-is. appIcon
    // is still a raw icon-theme-name-or-path string that we need to resolve ourselves.
    function resolveAppIcon(path) {
        if (!path) return ""
        if (path.startsWith("file://") || path.startsWith("http") || path.startsWith("image://")) return path
        if (path.startsWith("/")) return "file://" + path
        return Quickshell.iconPath(path, true)
    }

    // ---- Estados de hover (NOVO) ----
    // O Rumda usa HoverHandler só para PAUSAR a barra de progresso
    // (Notifications.qml:76, "paused: cardHover.hovered"). Aqui o hover também
    // acende a borda, para o card ter resposta visual clara de "você está
    // lendo isto" - coerente com os demais painéis, que já reagem no hover.
    HoverHandler {
        id: hover
    }

    // Em repouso a borda é discreta (Styles.border); no hover ela vira a cor de
    // urgência. Para "Critical" ela fica em tom de danger mesmo em repouso
    // (mais apagada), senão o único sinal de urgência sumiria quando o mouse
    // não estivesse sobre o card.
    border.color: root.urgency === NotificationUrgency.Critical
        ? Qt.rgba(Styles.danger.r, Styles.danger.g, Styles.danger.b, hover.hovered ? 1.0 : 0.55)
        : (hover.hovered ? root.urgencyColor : Styles.border)

    // ---- Animação de entrada/saída ----
    // Antes existia um "add:"/"remove:" Transition direto no ListView
    // (NotificationPopups.qml/HomeTab.qml), mas NUNCA tocava de verdade: o
    // model dos dois é um array JS comum reatribuído inteiro a cada mudança
    // (NotificationService.notifications/history), não um model incremental
    // de verdade (ListModel/QAbstractItemModel) - o Qt Quick só sabe animar
    // add/remove/displaced quando o PRÓPRIO model emite sinais linha-a-linha
    // de inserção/remoção; um array reatribuído inteiro vira um "reset" pro
    // ListView, sem animação nenhuma (testado ao vivo - as Transitions
    // ficavam declaradas mas nunca disparavam).
    //
    // Fix: o CARD anima a si mesmo (opacity/x via Behavior), sem depender
    // do ListView pra nada disso. Saída: ANTES de chamar a remoção de
    // verdade (dismiss()/expire()/removeFromHistory), guarda "closing" pra
    // esmaecer/deslizar primeiro - quando o item finalmente sai do array,
    // já tá com opacity 0, então o "corte" instantâneo do array fica
    // invisível. Entrada: mesma dança ao contrário, disparada em
    // Component.onCompleted.
    property bool closing: false
    property bool appeared: false
    property var closeAction: null

    readonly property bool settled: appeared && !closing

    opacity: settled ? 1 : 0
    x: settled ? 0 : 40

    // Assimetria proposital (não é só estética): entrada usa emphasizedDecel
    // (mais devagar, "pousa" suave) e saída usa emphasizedAccel (mais rápida,
    // "sai correndo") - mesmo padrão que o end-4/dots-hyprland usa pra
    // elementMoveEnter/elementMoveExit (Appearance.qml). É também o par de
    // curvas do Rumda pra entrada (OutCubic = desacelera) e saída
    // (InCubic = acelera).
    Behavior on opacity {
        NumberAnimation {
            duration: root.closing ? Motion.durationFast : Motion.durationNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.closing ? Motion.emphasizedAccel : Motion.emphasizedDecel
        }
    }
    Behavior on x {
        NumberAnimation {
            duration: root.closing ? Motion.durationFast : Motion.durationNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.closing ? Motion.emphasizedAccel : Motion.emphasizedDecel
        }
    }

    Component.onCompleted: root.appeared = true

    function startClose(action) {
        if (root.closing) return
        root.closeAction = action
        root.closing = true
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 160
        onTriggered: if (root.closeAction) root.closeAction()
    }

    TapHandler {
        onTapped: {
            if (!root.notification) return
            const def = root.notification.actions.find(a => a.identifier === "default")
            if (def) def.invoke()
        }
    }

    // ---- Temporização: UM único mecanismo (progress) ----
    // Antes eram DOIS mecanismos independentes para a mesma coisa: um "Timer"
    // que disparava expire(), e uma "NumberAnimation on width" que desenhava a
    // barra. Os dois podiam dessincronizar (o "interval" da Timer reage a
    // timeoutMs; a animação da barra reinicia do começo quando o delegate é
    // reassociado), e a barra não pausava no hover - a notificação sumia
    // enquanto se lia.
    //
    // Agora UM "progress" de 1 → 0 é a única fonte de verdade: a barra é
    // desenhada a partir dele e o expire() acontece no onFinished. Parar a
    // animação (hover/closing) NÃO dispara onFinished, então passar o mouse
    // sobre o card suspende os dois de forma consistente - é o mesmo mecanismo
    // do Rumda (Notifications.qml:71-78, "onFinished: slot.close(false)").
    //
    // "Linear" e não uma curva acentuada de propósito: a barra representa
    // TEMPO RESTANTE, e o olho do usuário a lê como um cronômetro.
    property real progress: 1.0

    NumberAnimation on progress {
        id: progressAnim
        running: root.autoExpires && !root.closing && !hover.hovered
        from: 1.0
        to: 0.0
        duration: root.timeoutMs
        easing.type: Easing.Linear
        onFinished: root.startClose(() => { if (root.notification) root.notification.expire() })
    }

    // Se o delegate for reassociado a outra notificação com a barra ainda em
    // curso, o progresso precisa voltar ao começo - senão a notificação nova
    // nasceria já com a barra quase vazia. (O ListView deste shell não recicla
    // delegates por padrão, mas não custa nada garantir.)
    onNotificationChanged: {
        if (!root.notification) return
        root.progress = 1.0
        if (root.autoExpires) progressAnim.restart()
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.leftMargin: root.cardPadding
        anchors.rightMargin: root.cardPadding
        anchors.topMargin: root.cardPadding
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                id: avatar
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: Styles.radiusSmall
                color: Styles.surfaceAlt

                // Avatar de letra (padrão do Rumda, Notifications.qml:163-178):
                // quando o app não manda imagem nem ícone resolvível, mostrar a
                // inicial do nome do app é mais informativo que um sino
                // genérico, e dá um acento de cor ao card.
                readonly property string letter: {
                    const src = (root.notification
                        ? (root.notification.appName || root.notification.summary)
                        : "") || ""
                    return src.length > 0 ? src.charAt(0).toUpperCase() : ""
                }

                Image {
                    id: iconImage
                    anchors.fill: parent
                    anchors.margins: 5
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                    source: root.notification
                        ? (root.notification.image || root.resolveAppIcon(root.notification.appIcon))
                        : ""
                }

                // Avatar de letra: ver "letter" acima.
                Text {
                    anchors.centerIn: parent
                    visible: iconImage.status !== Image.Ready && avatar.letter !== ""
                    text: avatar.letter
                    color: root.urgencyColor
                    font.pixelSize: 17
                    font.bold: true
                    font.family: Styles.fontFamily
                }

                // Sino como último recurso: continua sendo o que existia antes
                // para notificação sem nome nenhum.
                Icon {
                    anchors.centerIn: parent
                    visible: iconImage.status !== Image.Ready && avatar.letter === ""
                    icon: "bell"
                    size: 18
                    tint: Styles.foregroundMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Metadados: quem mandou. É a linha que some no Rumda (lá só
                // tem título e corpo), mas aqui ela é útil porque o mesmo card
                // lista o histórico do Dashboard, onde o appName é a informação
                // que distingue uma notificação da outra.
                Text {
                    text: root.notification ? root.notification.appName : ""
                    color: Styles.foregroundMuted
                    font.pixelSize: 10
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text.length > 0
                }

                // Título (primeiro nível da hierarquia). bumped de 13 → 14px
                // para marcar mais claramente a diferença em relação ao corpo,
                // como o Rumda faz (16px bold contra 14px).
                Text {
                    text: root.notification ? root.notification.summary : ""
                    color: Styles.foreground
                    font.pixelSize: 14
                    font.family: Styles.fontFamily
                    font.bold: true
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            IconButton {
                id: closeBtn
                size: 24
                icon: "close"
                // Baixa opacidade em repouso / cheia no hover: o botão continua
                // sempre clicável e visível, só deixa de competir com o texto.
                opacity: hover.hovered ? 1.0 : 0.45
                Behavior on opacity {
                    NumberAnimation { duration: Motion.durationFast; easing.type: Easing.OutCubic }
                }
                onClicked: {
                    if (!root.notification) return
                    // No histórico (Dashboard) "notification" é uma cópia
                    // simples dos dados, não o objeto Notification ao vivo -
                    // não tem .dismiss(), some da lista via removeFromHistory.
                    root.startClose(() => {
                        if (root.isPopup) root.notification.dismiss()
                        else NotificationService.removeFromHistory(root.notification.id)
                    })
                }
            }
        }

        Text {
            visible: text.length > 0
            text: root.notification ? root.notification.body : ""
            color: Styles.foregroundMuted
            font.pixelSize: 12
            font.family: Styles.fontFamily
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.notification && root.notification.actions.length > 0

            Repeater {
                model: root.notification ? root.notification.actions : []

                delegate: Button {
                    text: modelData.text
                    primary: false
                    onClicked: modelData.invoke()
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ---- Barra de progresso / tempo restante ----
    // Desenhada a partir de "progress", e com o mesmo recuo (cardPadding) do
    // conteúdo: dentro dos cantos arredondados, como no Rumda, em vez de
    // encostar na borda inferior.
    Rectangle {
        visible: root.autoExpires
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.cardPadding
        anchors.bottomMargin: root.barGap
        width: (root.width - root.cardPadding * 2) * root.progress
        height: root.barHeight
        radius: root.barHeight / 2
        color: root.urgencyColor
    }
}