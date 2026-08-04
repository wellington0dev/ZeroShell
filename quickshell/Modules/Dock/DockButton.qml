import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Theme
import qs.Widgets

// Um ícone do dock - tanto pra apps fixados quanto pra apps rodando sem
// estar fixados (ver DockWindow.qml). "entry" (DesktopEntry) e "toplevel"
// (janela rodando, ver Quickshell.Wayland) são independentes e podem vir
// os dois, só um, ou nenhum:
// - entry só: fixado, não rodando agora -> clique abre (entry.execute()).
// - toplevel só: rodando, não fixado -> clique foca (toplevel.activate()).
// - os dois: fixado E rodando -> clique foca (prioridade da janela viva
//   sobre abrir outra instância).
Item {
    id: root

    property var entry
    property var toplevel

    readonly property bool running: root.toplevel !== null

    signal activated()

    implicitWidth: 48
    implicitHeight: 48

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusButton
        color: hover.hovered ? Styles.surfaceAlt : "transparent"

        Behavior on color {
            ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
        }

        IconImage {
            id: iconImage
            anchors.centerIn: parent
            implicitSize: 32
            // Ícone de verdade do app (tema de ícones do sistema), não um
            // SVG monocromático nosso - dock mostra o logo real de cada
            // app, igual AppEntry.qml (Launcher) já faz.
            source: root.entry ? Quickshell.iconPath(root.entry.icon, true) : ""
        }

        // Ícone genérico (nosso, monocromático) quando o app não tem ícone
        // no tema instalado, ou "entry" nem existe (app rodando sem
        // DesktopEntry correspondente) - sem isso ficava um espaço vazio
        // sem feedback nenhum. Mesmo padrão de fallback de
        // NotificationCard.qml (ícone de sino quando a imagem falha).
        Icon {
            anchors.centerIn: parent
            visible: iconImage.status !== Image.Ready
            icon: "window"
            size: 26
            tint: Styles.foregroundMuted
        }
    }

    // Bolinha embaixo do ícone quando o app está rodando - acesa
    // (Styles.accent) se essa janela é a que está focada agora
    // (toplevel.activated), apagada (foregroundMuted) se só está aberta
    // em segundo plano.
    Rectangle {
        visible: root.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -3
        width: 5
        height: 5
        radius: 2.5
        color: (root.toplevel && root.toplevel.activated) ? Styles.accent : Styles.foregroundMuted
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
