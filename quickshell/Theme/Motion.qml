pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Curvas de animação "Material Design 3 expressive", adaptadas do
// Appearance.qml do end-4/dots-hyprland (um shell Quickshell bem conhecido).
// As curvas estão no formato [cx1,cy1, cx2,cy2, endx,endy] - exatamente o que
// "easing.bezierCurve" espera, então dá pra usar direto:
//
//   NumberAnimation {
//       duration: Motion.durationNormal
//       easing.type: Easing.BezierSpline
//       easing.bezierCurve: Motion.emphasizedDecel
//   }
//
// Por que não usar só "Easing.OutCubic" e afins? Essas curvas prontas do Qt
// são simétricas e meio "genéricas"; as curvas do Material 3 têm um formato
// assinatura (aceleram rápido, desaceleram devagar) que dá uma sensação mais
// "premium"/intencional ao movimento. Usadas hoje nos painéis que deslizam
// (Player, Helena) e nos pop-ins (Launcher, menu de energia).
Singleton {
    id: root

    // Durações em milissegundos - configuráveis em Configurações > Aparência
    // > Animações (MotionCustomizer.qml), por isso vêm de um FileView (igual
    // ao raio em Colors.qml) em vez de "readonly property int" direto: editar
    // o CONTEÚDO de um arquivo "pragma Singleton" faz o Quickshell recarregar
    // o módulo inteiro, fechando toda janela aberta - os valores de verdade
    // ficam em State/motion-config.json, e o FileView só recarrega os dados.
    //
    // As curvas (bezier) abaixo continuam fixas de propósito: não fazem parte
    // do pedido (só "o tempo das animações"), e não têm um jeito óbvio de
    // virar um slider - só as 3 durações são editáveis.
    readonly property int durationFast: adapter.fast
    readonly property int durationNormal: adapter.normal
    readonly property int durationSlow: adapter.slow

    function setDuration(key, value) {
        adapter[key] = value
        motionFile.writeAdapter()
    }

    // Sem "watchChanges"/"onFileChanged: reload()" de propósito, mesmo
    // motivo do radiusFile em Colors.qml: só este singleton (via
    // setDuration) escreve nesse arquivo.
    FileView {
        id: motionFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/motion-config.json"

        JsonAdapter {
            id: adapter
            property int fast: 150
            property int normal: 250
            property int slow: 400
        }
    }

    // Curvas M3 de uso geral.
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var standardDecel: [0, 0, 0, 1, 1, 1]

    // "Emphasized" - a curva assinatura do M3, uma S-curve suave sem overshoot.
    // Dois segmentos encadeados (12 números = dois grupos [controle1,controle2,fim]).
    readonly property var emphasized: [0.05, 0, 0.133333, 0.06, 0.166667, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]

    // "Expressive spatial" - overshoot mais pronunciado, pensado pra coisas que
    // se movem/mudam de tamanho (painéis deslizando, cards aparecendo/pop-in).
    readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
    readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
    readonly property var expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]

    // "Boing" - a clássica curva "easeOutBack": passa do tamanho final e volta,
    // dando aquela sensação de mola/quique. Usada nos pop-ins de janelas
    // modais (Launcher, menu de energia, menu de captura) - o overshoot é bem
    // mais forte que o do expressiveDefaultSpatial de propósito.
    readonly property var boing: [0.34, 1.56, 0.64, 1, 1, 1]
}
