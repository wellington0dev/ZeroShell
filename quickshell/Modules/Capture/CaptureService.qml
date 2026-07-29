pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.State

// Motor de captura/gravação de tela (grim + slurp + wf-recorder por baixo) e
// suas configurações persistidas (pasta de destino, copiar pro clipboard,
// notificar). Usado pelo CaptureMenu (a UI de escolha, aberta pela sidebar) e
// pela CapturePage nas Configurações (pra editar as opções).
//
// Os keybinds SUPER+SHIFT+S/G não passam pelo menu - abrem direto o
// CapturePicker (Modules/Capture/CapturePicker.qml), um overlay próprio que
// resolve tudo num gesto só (clique numa janela = só ela, clique fora = tela
// cheia, clique e arrasta = região livre), inspirado no "areapicker" do
// caelestia (github.com/caelestia-dots/shell) em vez do slurp usado pelo
// menu - slurp não dá pra fazer hover-preview nem decidir entre clique/
// arrasto no mesmo gesto sem heurísticas frágeis.
//
// Formato de "target" (usado só pelo CaptureMenu/script, não pelo picker):
// "region" (usuário desenha uma seleção), "window" (usuário clica numa
// janela) ou "fullscreen" (tela inteira).
Singleton {
    id: root

    // O CaptureMenu (Modules/Capture/CaptureMenu.qml) é destruído de verdade
    // sempre que fecha (é instanciado por um Loader - veja shell.qml), então
    // não pode ter seu próprio IpcHandler: quando fechado, ele simplesmente
    // não existe mais pra responder o "toggle". Por isso o handler mora aqui,
    // no singleton que vive o tempo todo.
    IpcHandler {
        target: "capture"

        // Abre/fecha o CaptureMenu (a UI de escolha manual de alvo) - hoje só
        // acessível pelo botão da sidebar, sem keybind dedicado.
        function toggle(): void {
            Visibility.captureMenuOpen = !Visibility.captureMenuOpen
        }
        // open/close explícitos (além do toggle acima) - scripts que
        // precisam de estado determinístico (ex.: debug-shell.sh) não podem
        // usar um toggle cego sem saber o estado atual antes.
        function open(): void { Visibility.captureMenuOpen = true }
        // Fecha tanto o CaptureMenu quanto o CapturePicker, se algum dos
        // dois estiver aberto - útil pra scripts (ex.: debug-shell.sh, que já
        // chama "capture close" ao encerrar) garantirem estado limpo sem
        // precisar saber qual dos dois tava aberto.
        function close(): void {
            Visibility.captureMenuOpen = false
            root.cancelPicker()
        }

        // Bound ao keybind SUPER+SHIFT+S no hyprland.lua: abre o
        // CapturePicker direto no modo screenshot, sem passar pelo menu.
        function screenshotAuto(): void { root.openPicker(false) }

        // Mesmo esquema do de cima, só que grava em vez de tirar print -
        // bound ao keybind SUPER+SHIFT+G. Chamar de novo enquanto já tá
        // gravando não abre o picker de novo (ver openPicker) - pra parar,
        // usa o botão da sidebar (CaptureIndicator.qml) ou o menu.
        function recordAuto(): void { root.openPicker(true) }
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

    // ---- CapturePicker (SUPER+SHIFT+S/G) ----
    // "pickerOpen" controla o Loader do CapturePicker em shell.qml -
    // destruído de verdade ao fechar (mesmo motivo do CaptureMenu: uma
    // superfície layer-shell "invisible" ainda disputaria com o grim/
    // wf-recorder pela superfície de tela cheia).
    property bool pickerOpen: false
    property bool pickerForRecording: false

    function openPicker(forRecording) {
        // Já gravando: SUPER+SHIFT+G de novo não deveria abrir o picker por
        // cima de uma gravação em andamento - usa o botão da sidebar/menu
        // pra parar.
        if (forRecording && root.recording) return
        root.pickerForRecording = forRecording
        root.pickerOpen = true
    }

    function cancelPicker() {
        root.pickerOpen = false
    }

    // Chamado pelo CapturePicker quando o usuário termina a seleção (clique,
    // clique fora ou arrasto). "geom" já vem pronto no formato "X,Y WxH", ou
    // vazio pra tela cheia - o picker resolve tudo sozinho, sem precisar do
    // capture-geometry.sh/slurp.
    function resolvePicker(geom) {
        root.pickerOpen = false
        // Mesmo atraso/motivo do requestScreenshot/requestRecording abaixo:
        // dá tempo do picker sumir da tela antes do grim/wf-recorder entrarem
        // em ação (senão a própria seleção/overlay apareceria no print).
        root.pendingAction = () => {
            if (root.pickerForRecording) root.startRecordingWithGeometry(geom)
            else root.screenshotWithGeometry(geom)
        }
        pendingActionTimer.restart()
    }

    // Resolve a geometria pro alvo pedido e entrega via callback(geom,
    // cancelled). "fullscreen" responde na hora (geom vazio = sem "-g",
    // nunca cancelado). "region" e "window" chamam capture-geometry.sh, que
    // só retorna quando o usuário termina de selecionar - geom vazio aqui
    // sempre quer dizer cancelado (Esc), ver comentário no script.
    function geometryFor(target, callback) {
        if (target === "fullscreen") {
            callback("", false)
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
                if (geometryProcess.callback) {
                    const geom = this.text.trim()
                    geometryProcess.callback(geom, !geom)
                }
            }
        }
    }

    // Dispara uma captura/gravação com um pequeno atraso, dando tempo do
    // CaptureMenu (que se fecha na hora, destruído de verdade por um Loader
    // - veja shell.qml) sumir da tela antes do grim/slurp entrarem em ação.
    // Fica AQUI (no singleton, que nunca é destruído) e não dentro do
    // CaptureMenu, porque um Timer dentro do menu seria destruído junto com
    // ele antes de disparar. Reusado também pelo CapturePicker (mesmo
    // problema, ver resolvePicker acima).
    property var pendingAction: null

    Timer {
        id: pendingActionTimer
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
        geometryFor(target, (geom, cancelled) => {
            // Seleção cancelada (slurp fechado com Esc, por exemplo) - aborta
            // em vez de tirar print da tela toda.
            if (cancelled) return
            root.screenshotWithGeometry(geom)
        })
    }

    function screenshotWithGeometry(geom) {
        const file = root.screenshotsDir + "/screenshot_" + root.timestamp() + ".png"
        screenshotProcess.command = [
            "bash", root.scriptsDir + "/capture-screenshot.sh",
            file, geom,
            root.copyToClipboard ? "1" : "0",
            root.notifyOnCapture ? "1" : "0"
        ]
        screenshotProcess.running = true
    }

    Process { id: screenshotProcess }

    // ---- Gravação ----
    function startRecording(target) {
        if (root.recording) return
        geometryFor(target, (geom, cancelled) => {
            if (cancelled) return
            root.startRecordingWithGeometry(geom)
        })
    }

    function startRecordingWithGeometry(geom) {
        if (root.recording) return
        const file = root.videosDir + "/recording_" + root.timestamp() + ".mp4"
        root.currentRecordingFile = file
        root.recordingSeconds = 0
        recordProcess.command = ["bash", root.scriptsDir + "/capture-record-start.sh", file, geom]
        recordProcess.running = true
        root.recording = true
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
