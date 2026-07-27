pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso de CPU, RAM e armazenamento, atualizados a cada poucos segundos via
// scripts/system-stats.sh (lê /proc/stat, /proc/meminfo e "df $HOME"). Usado
// só pela aba "Sistema" do Dashboard.
Singleton {
    id: root

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/Modules/Dashboard/scripts/system-stats.sh"

    property int cpuPercent: 0
    property int ramPercent: 0
    property int storagePercent: 0

    // O script já demora ~0.3s por causa da amostragem de CPU - o timer
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
                if (parts.length === 3) {
                    root.cpuPercent = parseInt(parts[0]) || 0
                    root.ramPercent = parseInt(parts[1]) || 0
                    root.storagePercent = parseInt(parts[2]) || 0
                }
            }
        }
    }
}
