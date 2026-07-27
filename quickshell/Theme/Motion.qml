pragma Singleton

import Quickshell

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
    // Durações em milissegundos.
    readonly property int durationFast: 150
    readonly property int durationNormal: 250
    readonly property int durationSlow: 400

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
