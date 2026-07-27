pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.State

// Motor de captura/gravação de tela (grim + slurp + wf-recorder por baixo) e
// suas configurações persistidas (pasta de destino, copiar pro clipboard,
// notificar). Usado pelo CaptureMenu (a UI de escolha) e pela CapturePage nas
// Configurações (pra editar as opções).
//
// Formato de "target": "region" (usuário desenha uma seleção), "window"
// (janela focada agora) ou "fullscreen" (tela inteira).
Singleton {
    id: root

    // O CaptureMenu (Modules/Capture/CaptureMenu.qml) é destruído de verdade
    // sempre que fecha (é instanciado por um Loader - veja shell.qml), então
    // não pode ter seu próprio IpcHandler: quando fechado, ele simplesmente
    // não existe mais pra responder o "toggle". Por isso o handler mora aqui,
    // no singleton que vive o tempo todo.
    IpcHandler {
        target: "capture"

        // Bound ao keybind SUPER+SHIFT+S no hyprland.lua:
        // qs ipc call capture toggle
        function toggle(): void {
            Visibility.captureMenuOpen = !Visibility.captureMenuOpen
        }
    }

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    // ---- Configurações persistidas em State/capture-settings.json ----
    property string screenshotsDir: settingsAdapter.screenshotsDir
    property string videosDir: settingsAdapter.videosDir
    property bool copyToClipboard: settingsAdapter.copyToClipboard
    property bool notifyOnCapture: settingsAdapter.notifyOnCapture

    function saveSettings(props) {
        for (const key in props) settingsAdapter[key] = props[key]
        settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/capture-settings.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: settingsAdapter
            property string screenshotsDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
            property string videosDir: Quickshell.env("HOME") + "/Videos"
            property bool copyToClipboard: true
            property bool notifyOnCapture: true
        }
    }

    // ---- Estado de gravação em andamento ----
    property bool recording: false
    property string currentRecordingFile: ""
    property int recordingSeconds: 0

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.recordingSeconds++
    }

    function formatElapsed() {
        const m = Math.floor(root.recordingSeconds / 60)
        const s = root.recordingSeconds % 60
        return m + ":" + String(s).padStart(2, "0")
    }

    function timestamp() {
        const d = new Date()
        const pad = n => String(n).padStart(2, "0")
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "_" +
               pad(d.getHours()) + "-" + pad(d.getMinutes()) + "-" + pad(d.getSeconds())
    }

    // Resolve a geometria pro alvo pedido e entrega via callback(geomString).
    // "fullscreen" responde na hora (string vazia = sem "-g"); "region" e
    // "window" chamam capture-geometry.sh, que só retorna quando o usuário
    // termina de selecionar (ou nada, se cancelar - ver comentário no script).
    function geometryFor(target, callback) {
        if (target === "fullscreen") {
            callback("")
            return
        }
        // Se uma seleção anterior ficou pendurada (ex.: slurp que nunca
        // recebeu o clique do usuário), "running = true" abaixo seria
        // ignorado nesse processo já em execução - a nova captura nunca
        // aconteceria. Mata a tentativa antiga antes de começar uma nova.
        if (geometryProcess.running) {
            geometryProcess.callback = null
            geometryProcess.running = false
        }
        geometryProcess.callback = callback
        geometryProcess.command = ["bash", root.scriptsDir + "/capture-geometry.sh", target]
        geometryProcess.running = true
    }

    Process {
        id: geometryProcess
        property var callback: null
        stdout: StdioCollector {
            onStreamFinished: {
                if (geometryProcess.callback) geometryProcess.callback(this.text.trim())
            }
        }
    }

    // Dispara uma captura/gravação com um pequeno atraso, dando tempo do
    // CaptureMenu (que se fecha na hora, destruído de verdade por um Loader
    // - veja shell.qml) sumir da tela antes do grim/slurp entrarem em ação.
    // Fica AQUI (no singleton, que nunca é destruído) e não dentro do
    // CaptureMenu, porque um Timer dentro do menu seria destruído junto com
    // ele antes de disparar.
    property var pendingAction: null

    Timer {
        id: pendingActionTimer
        // Pequena folga pra deixar o CaptureMenu (destruído de verdade pelo
        // Loader - veja shell.qml) sumir da tela antes do grim/slurp
        // entrarem em ação.
        interval: 250
        onTriggered: {
            if (root.pendingAction) root.pendingAction()
            root.pendingAction = null
        }
    }

    function requestScreenshot(target) {
        root.pendingAction = () => root.screenshot(target)
        pendingActionTimer.restart()
    }

    function requestRecording(target) {
        root.pendingAction = () => root.startRecording(target)
        pendingActionTimer.restart()
    }

    // ---- Screenshot ----
    function screenshot(target) {
        geometryFor(target, (geom) => {
            // Região/janela cancelada (slurp fechado com Esc, por exemplo)
            // retorna string vazia - aborta em vez de tirar print da tela toda.
            if (target !== "fullscreen" && !geom) return

            const file = root.screenshotsDir + "/screenshot_" + root.timestamp() + ".png"
            screenshotProcess.command = [
                "bash", root.scriptsDir + "/capture-screenshot.sh",
                file, geom,
                root.copyToClipboard ? "1" : "0",
                root.notifyOnCapture ? "1" : "0"
            ]
            screenshotProcess.running = true
        })
    }

    Process { id: screenshotProcess }

    // ---- Gravação ----
    function startRecording(target) {
        if (root.recording) return
        geometryFor(target, (geom) => {
            if (target !== "fullscreen" && !geom) return

            const file = root.videosDir + "/recording_" + root.timestamp() + ".mp4"
            root.currentRecordingFile = file
            root.recordingSeconds = 0
            recordProcess.command = ["bash", root.scriptsDir + "/capture-record-start.sh", file, geom]
            recordProcess.running = true
            root.recording = true
        })
    }

    function stopRecording() {
        if (!root.recording) return
        // running = false manda SIGTERM pro processo - graças ao "exec" no
        // script, quem recebe é o próprio wf-recorder, que finaliza o arquivo
        // de vídeo direito antes de sair.
        recordProcess.running = false
    }

    Process {
        id: recordProcess
        onExited: {
            root.recording = false
            if (root.notifyOnCapture && root.currentRecordingFile) {
                notifyProcess.command = ["notify-send", "Gravação de tela", "Salva em " + root.currentRecordingFile]
                notifyProcess.running = true
            }
        }
    }

    Process { id: notifyProcess }
}
