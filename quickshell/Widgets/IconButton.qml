import QtQuick
import qs.Theme

// Botão quadrado com um ícone no meio - o botão mais usado do shell (sidebar,
// cabeçalhos de painel, navegação das Configurações, controles do player...).
//
// Propriedades importantes:
// - "active": estado "ligado"/selecionado (fundo e borda ficam na cor de
//   destaque). Usado pra indicar "este painel está aberto agora" nos botões
//   da sidebar, ou "esta aba está selecionada" na navegação das Configurações.
// - "monochrome": repassado direto pro Icon interno (veja Icon.qml) - true
//   pinta o ícone com a cor do tema, false mantém a cor original do SVG
//   (usado pelos ícones de app do AppTray, que são logos coloridos).
// - "enabled" (herdada de Item): quando false, o Qt já bloqueia clique/hover
//   sozinho; aqui só reduzimos a opacidade pra dar feedback visual disso.
Item {
    id: root

    property string icon
    property int size: 36
    property bool active: false
    property bool monochrome: true

    signal clicked()

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusButton
        opacity: root.enabled ? 1 : 0.4
        color: root.active
            ? Qt.rgba(Styles.accent.r, Styles.accent.g, Styles.accent.b, 0.18)
            : (hover.hovered ? Styles.surfaceAlt : "transparent")
        border.color: root.active ? Styles.accent : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }

        Icon {
            anchors.centerIn: parent
            size: Math.max(10, root.size - 16)
            icon: root.icon
            monochrome: root.monochrome
            tint: root.active ? Styles.accent : Styles.foreground
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}
