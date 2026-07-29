import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

// Raio de canto por categoria (Shell/Botões/Inputs/Janelas) - usada pela aba
// "Aparência" das Configurações. Shell/Botões/Inputs são só CSS - mudam na
// hora (Colors.setRadius grava em State/radius-config.json, e todo
// componente já lê Colors.radiusShell/Button/Input reativamente). "Janelas"
// é diferente: não existe no quickshell, é o "decoration.rounding" do
// Hyprland - setRadius ainda grava o valor aqui (só pra UI lembrar a
// posição do slider), mas quem aplica de verdade é o script bash + hyprctl
// reload (ver set-window-radius.sh).
ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    spacing: Colors.spacing

    Process {
        id: windowRadiusProcess
        function run(value) {
            command = ["bash", root.scriptsDir + "/set-window-radius.sh", "" + value]
            running = true
        }
    }

    // Ponto único por onde toda mudança de raio passa - importante porque no
    // modo alinhado (Colors.radiusLinked) mexer em QUALQUER slider também
    // muda "window" nos bastidores (Colors.setRadius cuida disso), e "window"
    // é a única categoria que não é só CSS: precisa do hyprctl reload pra
    // valer de verdade, então dispara o Process sempre que isso pode ter
    // acontecido - não só quando quem mexeu foi o slider "Janelas" mesmo.
    function applyRadius(key, value) {
        Colors.setRadius(key, value)
        if (key === "window" || Colors.radiusLinked) windowRadiusProcess.run(Colors.radiusWindow)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacing

        Text {
            text: "Manter tudo alinhado"
            color: Colors.foreground
            font.pixelSize: 12
            font.family: Colors.fontFamily
            Layout.fillWidth: true
        }

        Switch {
            checked: Colors.radiusLinked
            onToggled: {
                Colors.setRadiusLinked(!Colors.radiusLinked)
                if (Colors.radiusLinked) windowRadiusProcess.run(Colors.radiusWindow)
            }
        }
    }

    Text {
        text: Colors.radiusLinked
            ? "Os 4 valores abaixo mudam juntos."
            : "Cada categoria tem seu próprio raio - um painel inteiro e um botãozinho não ficam bem com o mesmo número."
        color: Colors.foregroundMuted
        font.pixelSize: 11
        font.family: Colors.fontFamily
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Shell"
        value: Colors.radiusShell
        maxValue: 32
        onMoved: (v) => root.applyRadius("shell", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Botões"
        value: Colors.radiusButton
        maxValue: 24
        onMoved: (v) => root.applyRadius("button", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Inputs"
        value: Colors.radiusInput
        maxValue: 24
        onMoved: (v) => root.applyRadius("input", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Janelas"
        value: Colors.radiusWindow
        maxValue: 24
        onMoved: (v) => root.applyRadius("window", v)
    }

    Item { Layout.fillHeight: true }
}
