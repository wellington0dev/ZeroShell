import QtQuick
import qs.Theme

// Gráfico de linha minimalista (sparkline) - sem eixos, números ou grade,
// só a forma da série ao longo do tempo. Usado pelo NetworkMeter.qml pra
// mostrar o histórico recente de throughput ao lado dos números atuais.
// Desenha com Canvas (não QtQuick.Shapes como o RingMeter.qml): a série
// muda de TAMANHO enquanto os primeiros "historyLength" valores não
// chegaram (SystemStats.qml), então o número de pontos do traçado varia -
// mais simples de refazer um path do zero a cada "onPaint" do que
// reconciliar um Shape declarativo com pontos variáveis.
//
// "values" muda a cada ~3s (intervalo do SystemStats.qml) - sem animação,
// a linha inteira saltava pro formato novo instantaneamente, o que fica
// nervoso/ilegível numa série que já é curta. Por isso desenha
// "displayValues" (não "values" direto): a cada mudança, interpola de onde
// a linha estava pra onde ela devia estar, ponto a ponto, ao longo de
// "Motion.durationSlow" - dá aquela sensação de "onda" fluindo pro novo
// formato em vez de piscar.
Item {
    id: root

    property var values: []
    property color lineColor: "white"
    // 0 = escala automática (usa o maior valor da própria série, com piso 1
    // pra não dividir por zero quando tudo tá parado em 0).
    property real maxValue: 0
    property real lineWidth: 1.5
    property bool showDot: true

    property var displayValues: []
    property var animateFrom: []
    property real progress: 1

    // Posição (em coordenadas locais) do último ponto - só existe pra
    // "dot" abaixo (um Rectangle comum, não desenhado no Canvas) conseguir
    // pulsar com uma animação QML nativa em vez de precisar redesenhar o
    // Canvas inteiro a cada frame do pulso.
    readonly property real pad: showDot ? 4 : lineWidth
    readonly property real usableH: height - pad * 2
    readonly property real peak: Math.max(maxValue, displayValues.length ? Math.max(...displayValues) : 0, 1)
    readonly property real stepX: displayValues.length > 1 ? width / (displayValues.length - 1) : 0
    readonly property real lastX: displayValues.length ? (displayValues.length - 1) * stepX : 0
    readonly property real lastY: displayValues.length ? pad + usableH - (displayValues[displayValues.length - 1] / peak) * usableH : 0

    // Linear, não OutCubic - pedido explicitamente: a linha deve se mover
    // em velocidade constante (sem desacelerar no fim), não com a
    // sensação "amortecida" das curvas M3 usadas no resto do shell.
    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Motion.durationSlow
        easing.type: Easing.Linear
    }

    onValuesChanged: {
        // Comprimento mudou (histórico ainda enchendo, ou zerou) - não dá
        // pra interpolar índice a índice de forma que faça sentido (os
        // índices não representam os mesmos instantes de antes pro
        // depois), então só corta pro valor novo direto, sem animar essa
        // transição específica.
        if (animateFrom.length !== values.length) {
            animateFrom = values
            displayValues = values
            progress = 1
            canvas.requestPaint()
            return
        }

        animateFrom = displayValues
        anim.stop()
        progress = 0
        anim.start()
    }

    onProgressChanged: {
        if (animateFrom.length !== values.length) return
        const next = []
        for (let i = 0; i < values.length; i++) {
            next.push(animateFrom[i] + (values[i] - animateFrom[i]) * progress)
        }
        displayValues = next
        canvas.requestPaint()
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onLineColorChanged() { canvas.requestPaint() }
            function onMaxValueChanged() { canvas.requestPaint() }
            function onLineWidthChanged() { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            if (root.displayValues.length < 2) return

            ctx.strokeStyle = root.lineColor
            ctx.lineWidth = root.lineWidth
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.beginPath()

            for (let i = 0; i < root.displayValues.length; i++) {
                const x = i * root.stepX
                const y = root.pad + root.usableH - (root.displayValues[i] / root.peak) * root.usableH
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()
        }
    }

    // Ponta pulsante no último ponto - só um toque de "tá vivo", mesma
    // técnica (SequentialAnimation em opacity) do pontinho de gravação do
    // CaptureIndicator.qml. Posição segue "lastX"/"lastY" direto (sem
    // Behavior própria aqui): esses dois já vêm de "displayValues", que é
    // quem tá sendo animado ponto a ponto acima - dar um Behavior extra
    // aqui faria a bolinha correr atrás do próprio rastro da linha (mira um
    // alvo que já tá se movendo) em vez de ficar grudada na ponta dela.
    Rectangle {
        visible: root.showDot && root.displayValues.length > 0
        x: root.lastX - width / 2
        y: root.lastY - height / 2
        width: root.lineWidth * 2.8
        height: width
        radius: width / 2
        color: root.lineColor

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700 }
            NumberAnimation { to: 1; duration: 700 }
        }
    }
}
