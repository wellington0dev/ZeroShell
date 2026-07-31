pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso de CPU, RAM, armazenamento, temperatura do processador e throughput de
// rede, atualizados a cada poucos segundos via scripts/system-stats.sh (lê
// /proc/stat, /proc/meminfo, /proc/net/dev, /sys/class/thermal e "df
// $HOME"). Usado só pela aba "Sistema" do Dashboard.
Singleton {
    id: root

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/Modules/Dashboard/scripts/system-stats.sh"

    property int cpuPercent: 0
    property int ramPercent: 0
    property int storagePercent: 0
    property int cpuTemp: 0
    property int netRxKBps: 0
    property int netTxKBps: 0

    // Histórico curto de throughput pro gráfico de linha ao lado dos
    // números (NetworkMeter.qml) - mais antigo primeiro, sempre com no
    // máximo "historyLength" amostras (a cada 3s = ~2min de janela). Vive
    // aqui (não dentro do NetworkMeter) pra sobreviver à troca de aba: o
    // Loader do Dashboard destrói/recria o conteúdo da aba a cada troca
    // (ver DashboardWindow.qml), então um array local no widget reiniciaria
    // vazio toda vez que o usuário saísse e voltasse pra aba "Sistema".
    readonly property int historyLength: 25
    property var netRxHistory: []
    property var netTxHistory: []

    function pushHistory(arr, value) {
        const next = arr.concat([value])
        if (next.length > root.historyLength) next.shift()
        return next
    }

    // O script já demora ~0.3s por causa da amostragem de CPU/rede - o timer
    // só evita empilhar chamadas enquanto uma ainda está rodando.
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statsProcess.running) statsProcess.running = true
    }

    Process {
        id: statsProcess
        command: ["bash", root.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(" ")
                if (parts.length === 6) {
                    root.cpuPercent = parseInt(parts[0]) || 0
                    root.ramPercent = parseInt(parts[1]) || 0
                    root.storagePercent = parseInt(parts[2]) || 0
                    root.cpuTemp = parseInt(parts[3]) || 0
                    root.netRxKBps = parseInt(parts[4]) || 0
                    root.netTxKBps = parseInt(parts[5]) || 0
                    root.netRxHistory = root.pushHistory(root.netRxHistory, root.netRxKBps)
                    root.netTxHistory = root.pushHistory(root.netTxHistory, root.netTxKBps)
                }
            }
        }
    }
}
