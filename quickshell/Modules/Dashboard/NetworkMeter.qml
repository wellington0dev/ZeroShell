import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Card de rede no mesmo estilo "casca" do RingMeter.qml (cabeçalho com
// ícone+rótulo) - mas sem anel: throughput (KB/s) não tem uma escala
// natural de 0-100% pra preencher um gauge. Números (download/upload) à
// esquerda, gráfico de linha do histórico recente à direita - duas linhas
// sobrepostas no mesmo Sparkline (uma por direção), cada amostra vindo de
// SystemStats.netRxHistory/netTxHistory.
Rectangle {
    id: root

    property int rxKBps: 0
    property int txKBps: 0
    property var rxHistory: []
    property var txHistory: []

    radius: Styles.radiusShell
    color: Styles.surface
    border.color: Styles.border
    border.width: 1

    // KB/s vira MB/s acima de 1000 - "1234 KB/s" é mais difícil de ler
    // rápido que "1.2 MB/s".
    function formatRate(kbps) {
        if (kbps >= 1000) return (kbps / 1000).toFixed(1) + " MB/s"
        return kbps + " KB/s"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            Icon {
                icon: "wifi"
                size: 13
                tint: Styles.accent
            }

            Text {
                text: "Rede"
                color: Styles.foregroundMuted
                font.pixelSize: 10
                font.family: Styles.fontFamily
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            ColumnLayout {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                RowLayout {
                    spacing: 6

                    Text {
                        text: "↓"
                        color: Styles.accent
                        font.pixelSize: 13
                        font.family: Styles.fontFamily
                        font.bold: true
                    }

                    Text {
                        text: root.formatRate(root.rxKBps)
                        color: Styles.foreground
                        font.pixelSize: 13
                        font.family: Styles.fontFamily
                        font.bold: true
                    }
                }

                RowLayout {
                    spacing: 6

                    Text {
                        text: "↑"
                        color: Styles.accentAlt
                        font.pixelSize: 13
                        font.family: Styles.fontFamily
                        font.bold: true
                    }

                    Text {
                        text: root.formatRate(root.txKBps)
                        color: Styles.foreground
                        font.pixelSize: 13
                        font.family: Styles.fontFamily
                        font.bold: true
                    }
                }
            }

            // Duas linhas sobrepostas (Sparkline não sabe desenhar mais de
            // uma série - mais simples empilhar dois Canvas transparentes
            // do que ensinar o componente a fazer multi-série) - a escala
            // (maxValue) é COMPARTILHADA entre as duas, senão uma linha
            // fraca do lado de uma forte enganaria (cada uma escalando pro
            // próprio pico deixaria as duas sempre com a mesma altura
            // "cheia", mesmo que uma seja 10x mais forte que a outra).
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property real targetPeak: Math.max(1,
                    root.rxHistory.length ? Math.max(...root.rxHistory) : 0,
                    root.txHistory.length ? Math.max(...root.txHistory) : 0)

                // Escala animada (não usa "targetPeak" direto nos
                // Sparklines abaixo) - sem isso, um pico novo reescalava a
                // linha INTEIRA (inclusive os pontos antigos, que não
                // mudaram de valor nenhum) de golpe, o que lia como um
                // salto estranho mesmo com os pontos individuais já animando.
                property real animatedPeak: targetPeak
                // Linear, mesmo motivo/pedido do "progress" em Sparkline.qml
                // - velocidade constante, sem desacelerar no fim.
                Behavior on animatedPeak {
                    NumberAnimation { duration: Motion.durationSlow; easing.type: Easing.Linear }
                }

                Sparkline {
                    anchors.fill: parent
                    values: root.rxHistory
                    maxValue: parent.animatedPeak
                    lineColor: Styles.accent
                }

                Sparkline {
                    anchors.fill: parent
                    values: root.txHistory
                    maxValue: parent.animatedPeak
                    lineColor: Styles.accentAlt
                }
            }
        }
    }
}
