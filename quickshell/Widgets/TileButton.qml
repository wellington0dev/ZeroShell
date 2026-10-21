import QtQuick
import qs.Theme

// TileButton: botão de ícone em "tile" (quadrado), que é o botão que o
// Dashboard usa em tudo - perfil/energia, atalhos, player, brilho.
//
// Nasceu da unificação dos 20 botões que estavam copiados módulo a módulo no
// Dashboard do Rumda (DashControlExtras, DashPlayButtons, DashBrightnessControl
// e ProfileAndPower), que repetiam o mesmo bloco de ~45 linhas: Rectangle com
// raio/cor/borda, escala no hover, dois Behavior, MouseArea com cursor de
// mão e um Icon dentro.
//
// DIFERENÇA PRO Widgets/IconButton.qml (que fica valendo como está):
//   - a borda aqui é opcional e o hover é accent TRANSLÚCIDO com leve escala
//     (o IconButton usa surfaceAlt no hover e borda só no estado "active");
//   - o IconButton é desenhado em volta do ícone com padding fixo (size - 16)
//     e serve pra menus/cabeçalhos. Este aqui é o "botão de tile" do card.
//
// Propriedades que cobrem as variações que existiam no Dashboard:
//   hoverScale : -0.05 encolhe (botões normais), +0.05 cresce (play/pause),
//                 0 desliga o efeito
//   hoverOffset: px que o tile sobe no hover (0 = não mexe)
//   hoverColor / idleColor : cores dos dois estados (o display de brilho usava
//                 a invertida: surface no hover, accent parado)
//   showBorder : borda de 1px na cor do tema
Item {
    id: root

    // ---- conteúdo ----
    property string icon
    property int size: 36
    property int iconSize: Math.round(size * 0.65)
    property color tint: Styles.foreground
    property bool monochrome: true

    // ---- aparência ----
    readonly property real radius: Styles.radiusButton
    property color idleColor: Styles.surfaceAlt
    property color hoverColor: Qt.alpha(Styles.accent, 0.22)
    property bool showBorder: false
    property color borderColor: Styles.border

    // Efeito do hover: negativo encolhe, positivo cresce, 0 desliga.
    property real hoverScale: -0.05

    // Se está sob o mouse agora. Útil para quem posiciona o tile em volta de
    // algo (os botões do Dashboard forms um arco que se abre no hover).
    readonly property bool hovered: hover.hovered

    // Quanto o tile SOBE no hover, em px (0 = não mexe). É o "flutuar" que os
    // botões de brilho do Dashboard fazem (o de cima sobe, o de baixo desce -
    // nesse caso use hoverOffset negativo).
    property real hoverOffset: 0

    signal clicked()

    implicitWidth: size
    implicitHeight: size

    y: (hover.hovered && hoverOffset !== 0) ? -hoverOffset : 0
    Behavior on y {
        NumberAnimation {
            duration: Motion.durationFast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    Rectangle {
        id: tile

        anchors.fill: parent
        radius: root.radius
        color: hover.hovered ? root.hoverColor : root.idleColor
        border.width: root.showBorder ? 1 : 0
        border.color: root.borderColor

        scale: root.hoverScale !== 0 && hover.hovered ? 1 + root.hoverScale : 1
        transformOrigin: Item.Center

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        tint: root.tint
        monochrome: root.monochrome
    }

    HoverHandler { id: hover }
    TapHandler {
        onTapped: root.clicked()
    }
}