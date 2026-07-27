pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Motor do chat de voz (modo "walkie-talkie" da API da Helena - ver
// Modules/Helena/scripts/voice-turn.sh): grava o microfone com pw-record,
// manda o áudio pra API, e toca a resposta em áudio (se vier uma) com
// paplay. HelenaClient (o singleton do chat de texto) é reaproveitado pra
// autenticação (token) e pra lista de mensagens - a conversa de voz aparece
// junto com o histórico de texto normal.
Singleton {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/quickshell/Modules/Helena/scripts"
    readonly property string audioDir: Quickshell.env("HOME") + "/.cache/quickshell/helena-voice"

    property bool recording: false
    property bool processing: false
    property bool playing: false
    property string errorText: ""

    readonly property string statusText: {
        if (root.errorText) return root.errorText
        if (root.recording) return "Ouvindo..."
        if (root.processing) return "Pensando..."
        if (root.playing) return "Falando..."
        return "Toque pra falar"
    }

    property string currentRecordingFile: ""
    property double recordingStartedAt: 0

    // Abaixo disso, é toque sem querer (ou solta cedo demais) - não vale a
    // pena gastar uma chamada de API pra transcrever silêncio/ruído.
    readonly property int minRecordingMs: 400

    function showError(text) {
        root.errorText = text
        errorClearTimer.restart()
    }

    Timer {
        id: errorClearTimer
        interval: 2500
        onTriggered: root.errorText = ""
    }

    Component.onCompleted: mkdirProcess.running = true

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", root.audioDir]
    }

    function timestamp() {
        const d = new Date()
        const pad = n => String(n).padStart(2, "0")
        return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + "_" +
               pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds())
    }

    // Chamado pelo botão do VoiceWidget: um toque começa a gravar, o próximo
    // para e já dispara o envio.
    function toggle() {
        if (root.recording) stopAndSend()
        else startRecording()
    }

    function startRecording() {
        if (root.recording || root.processing) return
        if (!HelenaClient.loggedIn) {
            root.showError("Faça login no chat da Helena primeiro")
            return
        }
        root.errorText = ""
        root.recordingStartedAt = Date.now()
        root.currentRecordingFile = root.audioDir + "/rec_" + root.timestamp() + ".wav"
        recordProcess.command = ["pw-record", root.currentRecordingFile]
        recordProcess.running = true
        root.recording = true
    }

    function stopAndSend() {
        if (!root.recording) return
        // running = false manda SIGTERM direto pro pw-record (é o processo
        // filho direto, sem bash no meio) - ele fecha o cabeçalho do WAV
        // certinho antes de sair.
        recordProcess.running = false
    }

    Process {
        id: recordProcess
        onExited: {
            root.recording = false

            if (Date.now() - root.recordingStartedAt < root.minRecordingMs) {
                discardProcess.command = ["rm", "-f", root.currentRecordingFile]
                discardProcess.running = true
                root.showError("Gravação muito curta")
                return
            }

            root.processing = true
            turnProcess.command = [
                "bash", root.scriptsDir + "/voice-turn.sh",
                HelenaClient.baseUrl, HelenaClient.token,
                root.currentRecordingFile, root.audioDir
            ]
            turnProcess.running = true
        }
    }

    // Descarta gravações curtas demais (ver minRecordingMs acima) - só pra
    // não deixar lixo acumulando em audioDir.
    Process { id: discardProcess }

    Process {
        id: turnProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.processing = false
                let data = null
                try { data = JSON.parse(this.text) } catch (e) { /* falhou, tratado abaixo */ }

                if (!data) {
                    root.showError("Erro ao enviar o áudio")
                    return
                }

                let list = HelenaClient.messages.concat([data.message])
                if (data.replies) list = list.concat(data.replies)
                HelenaClient.messages = list

                if (data.audio_reply_file) {
                    playProcess.command = ["paplay", data.audio_reply_file]
                    playProcess.running = true
                }
            }
        }
    }

    Process {
        id: playProcess
        onRunningChanged: root.playing = running
    }
}
