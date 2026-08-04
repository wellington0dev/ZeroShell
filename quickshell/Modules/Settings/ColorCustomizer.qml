import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    spacing: Styles.spacing

    function applyColor(key, value) {
        const props = {}
        props[key] = value.toString()
        Styles.setCustom(props)
        // Picking a color by hand means the palette is custom now - stop the
        // next wallpaper change from silently overwriting it.
        Styles.setUseWallpaperColors(false)
    }

    // ---- Temas prontos ----
    // Paletas fixas (não derivadas do wallpaper) pra quem desligou "Cores
    // do wallpaper" e quer só escolher um tema pronto em vez de ajustar
    // cor por cor abaixo. Aplica as 10 cores de uma vez via Styles.setCustom
    // (aceita um objeto com várias chaves, não só uma) e já desliga "Cores
    // do wallpaper" - mesmo efeito de mexer em cada ColorSwatchRow uma por
    // uma, só que tudo junto.
    //
    // "Tokyo Night" é literalmente o fallback hardcoded de Theme/Styles.qml
    // (as cores que aparecem antes do primeiro colors.json existir) -
    // formalizado aqui como preset pra quem quiser voltar pra ele de
    // propósito, não só por acidente de não ter arquivo ainda.
    readonly property var presets: [
        {
            id: "tokyo-night", name: "Tokyo Night",
            colors: {
                background: "#1a1b26", surface: "#20212f", surfaceAlt: "#292a3a", border: "#33344a",
                foreground: "#c0caf5", foregroundMuted: "#565f89",
                accent: "#7aa2f7", accentAlt: "#bb9af7", danger: "#f7768e", success: "#9ece6a"
            }
        },
        {
            id: "catppuccin-mocha", name: "Catppuccin Mocha",
            colors: {
                background: "#1e1e2e", surface: "#313244", surfaceAlt: "#45475a", border: "#585b70",
                foreground: "#cdd6f4", foregroundMuted: "#a6adc8",
                accent: "#89b4fa", accentAlt: "#cba6f7", danger: "#f38ba8", success: "#a6e3a1"
            }
        },
        {
            id: "catppuccin-macchiato", name: "Catppuccin Macchiato",
            colors: {
                background: "#24273a", surface: "#363a4f", surfaceAlt: "#494d64", border: "#5b6078",
                foreground: "#cad3f5", foregroundMuted: "#a5adcb",
                accent: "#8aadf4", accentAlt: "#c6a0f6", danger: "#ed8796", success: "#a6da95"
            }
        },
        {
            id: "catppuccin-frappe", name: "Catppuccin Frappé",
            colors: {
                background: "#303446", surface: "#414559", surfaceAlt: "#51576d", border: "#626880",
                foreground: "#c6d0f5", foregroundMuted: "#a5adce",
                accent: "#8caaee", accentAlt: "#ca9ee6", danger: "#e78284", success: "#a6d189"
            }
        },
        {
            id: "catppuccin-latte", name: "Catppuccin Latte",
            colors: {
                background: "#eff1f5", surface: "#ccd0da", surfaceAlt: "#bcc0cc", border: "#acb0be",
                foreground: "#4c4f69", foregroundMuted: "#6c6f85",
                accent: "#1e66f5", accentAlt: "#8839ef", danger: "#d20f39", success: "#40a02b"
            }
        },
        {
            id: "nord", name: "Nord",
            colors: {
                background: "#2e3440", surface: "#3b4252", surfaceAlt: "#434c5e", border: "#4c566a",
                foreground: "#eceff4", foregroundMuted: "#d8dee9",
                accent: "#88c0d0", accentAlt: "#81a1c1", danger: "#bf616a", success: "#a3be8c"
            }
        },
        {
            id: "gruvbox-dark", name: "Gruvbox Dark",
            colors: {
                background: "#282828", surface: "#3c3836", surfaceAlt: "#504945", border: "#7c6f64",
                foreground: "#ebdbb2", foregroundMuted: "#a89984",
                accent: "#83a598", accentAlt: "#d3869b", danger: "#fb4934", success: "#b8bb26"
            }
        }
    ]

    // Compara as 10 cores do preset com as atuais (Styles.<key>.toString()
    // vira "#rrggbb", mesmo formato dos hex abaixo) só pra destacar com uma
    // borda qual preset tá ativo agora - não afeta o que é salvo.
    function isActivePreset(preset) {
        for (const key in preset.colors) {
            if (Styles[key].toString() !== preset.colors[key]) return false
        }
        return true
    }

    function applyPreset(preset) {
        Styles.setCustom(preset.colors)
        Styles.setUseWallpaperColors(false)
    }

    FileView {
        id: currentWallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
    }

    Process {
        id: resetProcess
        function run(args) { command = args; running = true }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Cada cor é salva assim que você escolhe."
            color: Styles.foregroundMuted
            font.pixelSize: 11
            font.family: Styles.fontFamily
            Layout.fillWidth: true
        }

        Button {
            text: "Restaurar cores do wallpaper"
            primary: false
            onClicked: {
                const wp = (currentWallpaperFile.text() || "").trim()
                Styles.setUseWallpaperColors(true)
                if (wp) resetProcess.run(["bash", root.scriptsDir + "/apply-theme.sh", wp])
            }
        }
    }

    // Um Flickable só pra TUDO abaixo (temas prontos + cores uma por uma),
    // não só pra lista de cores - antes só a lista rolava, e numa janela
    // pequena (SettingsWindow.qml tem minimumSize 600x420) os cards de
    // tema pronto podiam empurrar a lista de cores pra fora sem dar pra
    // alcançar nenhum dos dois.
    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: Styles.spacing

            Text {
                text: "Temas prontos"
                color: Styles.foreground
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: Styles.spacing

                Repeater {
                    model: root.presets

                    delegate: Rectangle {
                        id: card

                        required property var modelData

                        width: 120
                        height: 64
                        radius: Styles.radiusSmall
                        // O preview usa as cores do PRÓPRIO preset (não as
                        // do tema atual) - fundo, texto e os pontinhos de
                        // destaque/sucesso/perigo do card mostram como
                        // aquele tema realmente fica, não o tema em uso
                        // agora.
                        color: card.modelData.colors.background
                        border.width: root.isActivePreset(card.modelData) ? 2 : 1
                        border.color: root.isActivePreset(card.modelData) ? Styles.accent : card.modelData.colors.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                spacing: 4

                                Repeater {
                                    model: [card.modelData.colors.accent, card.modelData.colors.success, card.modelData.colors.danger]

                                    delegate: Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: modelData
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                text: card.modelData.name
                                color: card.modelData.colors.foreground
                                font.pixelSize: 11
                                font.family: Styles.fontFamily
                                font.bold: true
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }

                        TapHandler { onTapped: root.applyPreset(card.modelData) }
                    }
                }
            }

            ColorSwatchRow { label: "Fundo"; key: "background"; value: Styles.background; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície"; key: "surface"; value: Styles.surface; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície alternativa"; key: "surfaceAlt"; value: Styles.surfaceAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Borda"; key: "border"; value: Styles.border; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto"; key: "foreground"; value: Styles.foreground; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto secundário"; key: "foregroundMuted"; value: Styles.foregroundMuted; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque"; key: "accent"; value: Styles.accent; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque alternativo"; key: "accentAlt"; value: Styles.accentAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Perigo"; key: "danger"; value: Styles.danger; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Sucesso"; key: "success"; value: Styles.success; onChanged: (k, v) => root.applyColor(k, v) }
        }
    }
}
