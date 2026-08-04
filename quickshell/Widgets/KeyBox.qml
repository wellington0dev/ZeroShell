import QtQuick
import qs.Theme

// Caixinha que mostra o nome de uma tecla (ex.: "SUPER", "T", "—" quando
// vazia) - usado na aba Atalhos (Modules/Settings/KeybindsPage.qml) pra
// exibir/gravar cada tecla de um atalho, uma por vez.
//
// - "fixed: true" - só exibição, sem clique (usado pra mostrar o mainMod
//   dentro da linha de cada atalho, já que ele só muda na linha do topo).
// - "capturing: true" - realce indicando que a próxima tecla pressionada
//   vai preencher esta caixa.
// - clique (quando não "fixed") dispara "tapped"; um "×" aparece no hover
//   quando a caixa tem texto e não é fixa, disparando "cleared".
Item {
    id: root

    property string text: ""
    property bool fixed: false
    property bool capturing: false

    signal tapped()
    signal cleared()

    implicitWidth: Math.max(34, label.implicitWidth + 18)
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusButton
        color: root.capturing
            ? Qt.rgba(Styles.accent.r, Styles.accent.g, Styles.accent.b, 0.18)
            : (hover.hovered && !root.fixed ? Styles.surfaceAlt : Styles.surface)
        border.color: root.capturing ? Styles.accent : Styles.border
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.capturing ? "..." : (root.text.length > 0 ? root.text : "—")
            color: root.text.length > 0 ? Styles.foreground : Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
        }

        Rectangle {
            visible: !root.fixed && root.text.length > 0 && hover.hovered && !root.capturing
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: -4
            width: 14
            height: 14
            radius: 7
            color: Styles.surfaceAlt
            border.color: Styles.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "×"
                color: Styles.foreground
                font.pixelSize: 10
                font.family: Styles.fontFamily
            }

            TapHandler { onTapped: root.cleared() }
        }
    }

    HoverHandler { id: hover; enabled: !root.fixed }
    TapHandler { enabled: !root.fixed; onTapped: root.tapped() }
}
