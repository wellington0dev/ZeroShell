import QtQuick
import qs.Theme

// Componente auxiliar (QtObject, sem elemento visual próprio) que calcula os
// valores de opacidade/escala/deslocamento pra abrir/fechar QUALQUER painel
// do shell, de acordo com o tipo escolhido em Configurações > Aparência >
// Animações (Motion.animationType: "slide", "popup" ou "fade") - centraliza
// a decisão de QUE TIPO usar num lugar só, sem duplicar a lógica em cada
// painel. Cada painel só aplica os valores computados aqui
// (targetOpacity/targetScale/slideOffset) no seu próprio mecanismo de
// posicionamento (alguns usam margins.top da própria janela, outros
// anchors.bottomMargin/rightMargin do card) - PanelAnim não tenta unificar
// ISSO, só qual curva/tipo usar.
//
// Uso típico (num painel que desliza a partir do topo, ex.: Dashboard):
//
//   PanelAnim { id: anim; open: DashboardState.open; edge: "top"; distance: root.implicitHeight }
//
//   visible: anim.shouldBeVisible  // NUNCA "visible: DashboardState.open"
//                                  // direto - essencial pros modos popup/
//                                  // fade (sem isso a superfície continua
//                                  // ocupando o mesmo lugar sempre, só
//                                  // invisível, e rouba hover/clique de quem
//                                  // tiver perto - já causou um bug de
//                                  // verdade no VolumePanel.qml antes desta
//                                  // ficar pronta) E pro modo slide (sem
//                                  // isso a superfície desmapeia ANTES da
//                                  // nossa animação de saída terminar - ver
//                                  // comentário de "shouldBeVisible" abaixo).
//   margins.top: anim.slideOffset
//   Behavior on margins.top { NumberAnimation { duration: Motion.durationNormal; ... } }
//
//   Rectangle {
//       id: card
//       opacity: anim.targetOpacity
//       scale: anim.targetScale
//       transformOrigin: Item.Top
//       Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }
//       Behavior on scale { NumberAnimation { duration: Motion.durationNormal; easing.bezierCurve: Motion.boing } }
//   }
QtObject {
    id: root

    property bool open: false
    // De onde o painel "sai"/entra no modo slide - "top"|"bottom"|"left"|"right".
    property string edge: "bottom"
    // Distância (px) percorrida no modo slide - cada painel passa o próprio
    // tamanho (altura pra top/bottom, largura pra left/right).
    property real distance: 40

    readonly property real targetOpacity: open ? 1 : 0
    readonly property real targetScale: (Motion.animationType === "popup" && !open) ? 0.9 : 1

    // Só diferente de zero no modo "slide" com o painel fechado - SEMPRE
    // negativo, não importa a borda. Contra a intuição à primeira vista, mas
    // é assim que "anchors.<lado>Margin" funciona no Qt pras 4 direções:
    // margin negativo sempre empurra o item pra fora da tela NA DIREÇÃO
    // DAQUELE MESMO LADO (topMargin negativo → sai por cima, bottomMargin
    // negativo → sai por baixo, leftMargin negativo → sai pela esquerda,
    // rightMargin negativo → sai pela direita) - cada painel já aplica este
    // valor na margin do PRÓPRIO lado (bottomMargin pra "bottom",
    // rightMargin pra "right", etc.), então não tem sinal pra inverter aqui.
    // Isso ERA invertido pra bottom/right (bug real, visto ao vivo: painéis
    // ancorados embaixo/à direita deslizavam pro lado errado em vez de sumir
    // na própria borda) - "edge" continua existindo só pra documentar de
    // onde cada painel entra, não afeta mais o sinal.
    readonly property real slideOffset: (Motion.animationType !== "slide" || open) ? 0 : -distance

    // Pra "visible" da PanelWindow (use "anim.shouldBeVisible" em vez de
    // ligar direto no "open" de cada painel). Fica true na hora ao abrir,
    // mas só vira false Motion.durationNormal DEPOIS de fechar - dando
    // tempo da animação de saída (slide/fade/escala) realmente terminar
    // antes da superfície desmapear.
    //
    // Por quê: mapear/desmapear uma superfície layer-shell TAMBÉM dispara a
    // animação de layer do próprio Hyprland (layersOut, hypr/modules/
    // appearance.lua - "style = fade"), correndo em paralelo e sem
    // sincronia nenhuma com a nossa. Ligando "visible" direto em "open",
    // a superfície desmapeava na hora que "open" virava false - a nossa
    // animação de saída não tinha tempo de rodar, só o fade do compositor
    // aparecia. O Dock nunca teve esse problema porque a superfície dele
    // nunca desmapeia (só o card interno desliza) - aqui é o mesmo
    // princípio, só que adiando o desmapeamento em vez de nunca desmapear.
    readonly property bool shouldBeVisible: open || hideTimer.running

    onOpenChanged: if (!open) hideTimer.restart()

    // QtObject não tem "default property" pra filhos soltos (só Item tem,
    // via "data") - por isso o Timer é uma property normal (com um Timer
    // como valor), não um filho anônimo "Timer { ... }" solto no corpo.
    property Timer hideTimer: Timer {
        interval: Motion.durationNormal
    }
}
