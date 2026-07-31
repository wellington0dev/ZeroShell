import QtQuick
import QtQuick.Effects
import qs.Icons
import qs.Theme

// Renderiza um dos SVGs em Icons/ (veja Icons/Icons.qml) com a cor do tema.
// É o componente-base usado por quase todo ícone do shell (IconButton usa
// este componente por baixo dos panos).
//
// Como funciona: os SVGs em Icons/ são desenhados em branco puro (#ffffff).
// Em vez de ter um arquivo por cor, carregamos o SVG normalmente numa Image
// (invisível) e usamos um MultiEffect com "colorization: 1" pra recolorir
// 100% do desenho pela cor "tint" - assim um ícone só de traços brancos vira
// qualquer cor do tema sem precisar de SVGs duplicados.
//
// Exceção: ícones de marca (Spotify, Discord, Steam) já têm cor própria no
// próprio arquivo SVG e não devem ser recoloridos - para esses, "monochrome:
// false" desliga o MultiEffect e mostra a Image original direto.
Item {
    id: root

    property string icon
    property color tint: Styles.foreground
    property bool monochrome: true
    property int size: 20

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.icon ? Icons.path(root.icon) : ""
        // Carrega em 2x o tamanho final para ficar nítido em telas HiDPI.
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        smooth: true
        asynchronous: true
        visible: !root.monochrome
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.monochrome
        colorization: 1
        colorizationColor: root.tint
    }
}
