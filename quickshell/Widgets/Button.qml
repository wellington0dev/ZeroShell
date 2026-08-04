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
//
// "flashSuccess()" - pisca o fundo em Styles.success por um instante, pra
// confirmar visualmente que uma ação assíncrona (salvar, atualizar...) deu
// certo, sem mudar o texto (evita o botão mudar de largura/empurrar vizinho
// de layout durante o flash). Quem chama decide QUANDO chamar - geralmente
// dentro do callback de sucesso de uma chamada, não direto no onClicked.
Item {
    id: root

    property string text: ""
    property bool primary: true
    readonly property bool showingSuccess: successTimer.running

    signal clicked()

    function flashSuccess() { successTimer.restart() }

    Timer { id: successTimer; interval: 1300 }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusButton
        opacity: root.enabled ? 1 : 0.5
        color: root.showingSuccess
            ? Styles.success
            : root.primary
                ? (hover.hovered ? Styles.accentAlt : Styles.accent)
                : (hover.hovered ? Styles.surfaceAlt : Styles.surface)
        border.color: (root.primary || root.showingSuccess) ? "transparent" : Styles.border
        border.width: (root.primary || root.showingSuccess) ? 0 : 1

        Behavior on color {
            ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: (root.primary || root.showingSuccess) ? Styles.background : Styles.foreground
            font.pixelSize: 12
            font.family: Styles.fontFamily
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}
