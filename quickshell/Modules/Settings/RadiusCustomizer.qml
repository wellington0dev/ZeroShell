import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

// Raio de canto por categoria (Shell/Botões/Inputs/Janelas) - usada pela aba
// "Aparência" das Configurações. Shell/Botões/Inputs são só CSS - mudam na
// hora (Styles.setRadius grava em State/radius-config.json, e todo
// componente já lê Styles.radiusShell/Button/Input reativamente). "Janelas"
// é diferente: não existe no quickshell, é o "decoration.rounding" do
// Hyprland - setRadius ainda grava o valor aqui (só pra UI lembrar a
// posição do slider), mas quem aplica de verdade é o script bash + hyprctl
// reload (ver set-window-radius.sh).
ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    spacing: Styles.spacing

    Process {
        id: windowRadiusProcess
        function run(value) {
            command = ["bash", root.scriptsDir + "/set-window-radius.sh", "" + value]
            running = true
        }
    }

    // Ponto único por onde toda mudança de raio passa - importante porque no
    // modo alinhado (Styles.radiusLinked) mexer em QUALQUER slider também
    // muda "window" nos bastidores (Styles.setRadius cuida disso), e "window"
    // é a única categoria que não é só CSS: precisa do hyprctl reload pra
    // valer de verdade, então dispara o Process sempre que isso pode ter
    // acontecido - não só quando quem mexeu foi o slider "Janelas" mesmo.
    function applyRadius(key, value) {
        Styles.setRadius(key, value)
        if (key === "window" || Styles.radiusLinked) windowRadiusProcess.run(Styles.radiusWindow)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Styles.spacing

        Text {
            text: "Manter tudo alinhado"
            color: Styles.foreground
            font.pixelSize: 12
            font.family: Styles.fontFamily
            Layout.fillWidth: true
        }

        Switch {
            checked: Styles.radiusLinked
            onToggled: {
                Styles.setRadiusLinked(!Styles.radiusLinked)
                if (Styles.radiusLinked) windowRadiusProcess.run(Styles.radiusWindow)
            }
        }
    }

    Text {
        text: Styles.radiusLinked
            ? "Os 4 valores abaixo mudam juntos."
            : "Cada categoria tem seu próprio raio - um painel inteiro e um botãozinho não ficam bem com o mesmo número."
        color: Styles.foregroundMuted
        font.pixelSize: 11
        font.family: Styles.fontFamily
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Shell"
        value: Styles.radiusShell
        maxValue: 32
        onMoved: (v) => root.applyRadius("shell", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Botões"
        value: Styles.radiusButton
        maxValue: 24
        onMoved: (v) => root.applyRadius("button", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Inputs"
        value: Styles.radiusInput
        maxValue: 24
        onMoved: (v) => root.applyRadius("input", v)
    }

    RadiusRow {
        Layout.fillWidth: true
        label: "Janelas"
        value: Styles.radiusWindow
        maxValue: 24
        onMoved: (v) => root.applyRadius("window", v)
    }

    Item { Layout.fillHeight: true }
}
