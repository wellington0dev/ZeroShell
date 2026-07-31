import QtQuick
import qs.Theme

// Botão de texto (com largura automática baseada no texto). Duas variantes
// visuais controladas por "primary":
// - primary: true (padrão) - preenchido com a cor de destaque, pra ação
//   principal de uma tela (ex.: "Entrar", "Conectar").
// - primary: false - contorno neutro, pra ações secundárias (ex.: "Cancelar",
//   "Restaurar cores do wallpaper").
//
// A largura (implicitWidth) é calculada a partir do texto interno + um
// respiro fixo de 24px, então o botão nunca fica maior que o necessário.
Item {
    id: root

    property string text: ""
    property bool primary: true

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusButton
        opacity: root.enabled ? 1 : 0.5
        color: root.primary
            ? (hover.hovered ? Styles.accentAlt : Styles.accent)
            : (hover.hovered ? Styles.surfaceAlt : Styles.surface)
        border.color: root.primary ? "transparent" : Styles.border
        border.width: root.primary ? 0 : 1

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: root.primary ? Styles.background : Styles.foreground
            font.pixelSize: 12
            font.family: Styles.fontFamily
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}
