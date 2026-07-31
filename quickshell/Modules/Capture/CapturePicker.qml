import QtQuick
import Quickshell
import Quickshell.Io
import qs.Theme

// Overlay de seleção pra SUPER+SHIFT+S (screenshot) e SUPER+SHIFT+G
// (gravação) - um gesto só decide tudo, sem menu antes:
//   - passar o mouse por cima de uma janela já mostra a prévia dela (clicar
//     sem arrastar captura só ela);
//   - passar por cima de área vazia mostra a tela toda (clicar sem arrastar
//     = tela cheia);
//   - clicar e ARRASTAR sempre vira uma região livre, ignorando o contorno
//     das janelas.
// Inspirado no "areapicker" do caelestia (github.com/caelestia-dots/shell,
// modules/areapicker/Picker.qml) - um MouseArea de tela cheia com hover
// nativo, em vez do slurp usado pelo CaptureMenu: slurp não dá pra fazer
// preview ao passar o mouse nem decidir entre clique/arrasto no mesmo gesto
// sem heurística frágil (testado - clique sintético via ydotool confundia o
// slurp com cancelamento).
//
// Instanciado por um Loader em shell.qml (destruído de verdade ao fechar,
// não só escondido) - mesmo motivo do CaptureMenu.qml: uma superfície
// layer-shell "invisible" ainda disputaria com o grim/wf-recorder pela
// superfície de tela cheia na hora de capturar.
PanelWindow {
    id: pickerRoot

    readonly property bool recording: CaptureService.pickerForRecording

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Lista de janelas do workspace atual - atualizada periodicamente (não só
    // uma vez ao abrir) porque o picker pode ficar aberto tempo suficiente
    // pro usuário abrir/fechar/redimensionar alguma janela no meio da
    // seleção (visto ao vivo: uma janela nova não aparecia pro hover até
    // fechar e abrir o picker de novo).
    property var windows: []

    Component.onCompleted: clientsProcess.running = true

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: if (!clientsProcess.running) clientsProcess.running = true
    }

    // "hyprctl clients" devolve TODAS as janelas de TODOS os workspaces -
    // "mapped"/"hidden" indicam se a superfície existe, não se o workspace
    // dela tá em foco agora. Sem filtrar por "workspace.id" aqui, uma janela
    // de outro workspace (invisível, mas com "mapped: true" igual) podia
    // "vencer" o hit-test por engano (visto ao vivo: o VSCode de outro
    // workspace, cuja caixa cobria as duas janelas do workspace de teste,
    // sempre batia primeiro). Por isso busca o workspace ativo TAMBÉM, via
    // jq combinando os dois "hyprctl -j" numa saída só.
    Process {
        id: clientsProcess
        command: ["bash", "-c", "jq -n --argjson ws \"$(hyprctl activeworkspace -j)\" --argjson clients \"$(hyprctl clients -j)\" '{ws:$ws, clients:$clients}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const wsId = data.ws.id
                    pickerRoot.windows = data.clients
                        .filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id === wsId)
                        .map(c => ({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1] }))
                } catch (e) {
                    pickerRoot.windows = []
                }
                // Só re-avalia o hover se não tiver arrasto em andamento - um
                // refresh periódico no meio de um arrasto não deve pular a
                // seleção livre de volta pro hover de janela.
                if (!area.pressed) area.updateHover(area.mouseX, area.mouseY)
            }
        }
    }

    // Escurece de leve o fundo todo - só pra deixar óbvio que o modo de
    // seleção tá ativo, sem competir visualmente com o retângulo de seleção.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.15
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        focus: true

        property real sx: 0
        property real sy: 0
        property real ex: width
        property real ey: height
        property bool hoveringWindow: false
        property real pressX: 0
        property real pressY: 0

        function hitTest(x, y) {
            for (const w of pickerRoot.windows) {
                if (x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) return w
            }
            return null
        }

        function updateHover(x, y) {
            const hit = hitTest(x, y)
            if (hit) {
                hoveringWindow = true
                sx = hit.x; sy = hit.y; ex = hit.x + hit.w; ey = hit.y + hit.h
            } else {
                hoveringWindow = false
                sx = 0; sy = 0; ex = width; ey = height
            }
        }

        Component.onCompleted: updateHover(mouseX, mouseY)

        onPositionChanged: (mouse) => {
            if (pressed) {
                sx = Math.min(pressX, mouse.x)
                sy = Math.min(pressY, mouse.y)
                ex = Math.max(pressX, mouse.x)
                ey = Math.max(pressY, mouse.y)
            } else {
                updateHover(mouse.x, mouse.y)
            }
        }

        onPressed: (mouse) => {
            pressX = mouse.x
            pressY = mouse.y
        }

        onReleased: (mouse) => {
            const dragged = Math.abs(mouse.x - pressX) > 4 || Math.abs(mouse.y - pressY) > 4

            let geom = ""
            if (dragged) {
                const x = Math.round(Math.min(pressX, mouse.x))
                const y = Math.round(Math.min(pressY, mouse.y))
                const w = Math.round(Math.abs(mouse.x - pressX))
                const h = Math.round(Math.abs(mouse.y - pressY))
                geom = x + "," + y + " " + w + "x" + h
            } else {
                const hit = hitTest(mouse.x, mouse.y)
                // Sem "hit" = clicou fora de qualquer janela -> geom fica
                // vazio, CaptureService entende isso como "tela cheia".
                if (hit) geom = hit.x + "," + hit.y + " " + hit.w + "x" + hit.h
            }

            CaptureService.resolvePicker(geom)
        }

        Keys.onEscapePressed: CaptureService.cancelPicker()

        Rectangle {
            id: selection

            x: area.sx
            y: area.sy
            width: area.ex - area.sx
            height: area.ey - area.sy
            radius: area.hoveringWindow ? Styles.radiusShell : 0
            color: pickerRoot.recording ? Styles.danger : Styles.accent
            opacity: 0.15
            border.color: pickerRoot.recording ? Styles.danger : Styles.accent
            border.width: 2

            Behavior on x { enabled: !area.pressed; NumberAnimation { duration: Motion.durationFast } }
            Behavior on y { enabled: !area.pressed; NumberAnimation { duration: Motion.durationFast } }
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: Motion.durationFast } }
            Behavior on height { enabled: !area.pressed; NumberAnimation { duration: Motion.durationFast } }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 8
                radius: Styles.radiusButton
                color: Styles.background
                width: label.implicitWidth + 16
                height: label.implicitHeight + 8
                visible: selection.width > width + 16 && selection.height > height + 16

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: !area.pressed && !area.hoveringWindow
                        ? (pickerRoot.recording ? "Gravar tela cheia" : "Tela cheia")
                        : (area.hoveringWindow
                            ? (pickerRoot.recording ? "Gravar janela" : "Janela")
                            : (pickerRoot.recording ? "Gravar região" : "Região"))
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                }
            }
        }
    }
}
