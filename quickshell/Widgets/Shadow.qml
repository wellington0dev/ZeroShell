import QtQuick
import QtQuick.Effects

// Sombra de profundidade para painéis que não ganham sombra do compositor.
//
// Contexto: janelas de verdade (FloatingWindow, como a de Configurações)
// recebem sombra automática do Hyprland (config em hyprland.lua,
// decoration.shadow). Mas boa parte do shell (Sidebar, Dashboard, Volume,
// Launcher, menu de energia) usa PanelWindow, que é uma superfície
// "layer-shell" - um tipo de janela especial pra barras/painéis que o
// Hyprland não decora com sombra. Sem isso, esses painéis pareceriam "colados"
// no fundo, sem profundidade.
//
// Como usar: declare este componente ANTES do Rectangle que quer sombrear,
// apontando "target" pra ele. Funciona mesmo com "target: bg" referenciando
// um id declarado DEPOIS no arquivo - o QML só resolve os ids depois que toda
// a árvore termina de ser montada, então a ordem de declaração não importa
// aqui, só a ordem em que aparecem na tela (Shadow primeiro = fica atrás).
//
//   Shadow { target: bg }
//   Rectangle { id: bg; ... }
MultiEffect {
    id: root

    property Item target

    source: target
    anchors.fill: target
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.5)
    shadowBlur: 0.7
    shadowVerticalOffset: 6
    shadowHorizontalOffset: 0
    autoPaddingEnabled: true
}
