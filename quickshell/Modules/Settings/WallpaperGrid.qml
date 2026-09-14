import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Wallpapers"

    spacing: Styles.spacing

    FileView {
        id: currentFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
        watchChanges: true
        onFileChanged: reload()
    }

    readonly property string current: (currentFile.text() || "").trim()

    function run(args) {
        applyProcess.command = args
        applyProcess.running = true
    }

    Process { id: applyProcess }

    // Os 9 algoritmos de esquema de cor que o matugen sabe gerar (`--type`,
    // ver `matugen --help`) - controla como os tons neutros de fundo/
    // superfície/texto são derivados do wallpaper (accent/accentAlt são
    // amostrados direto da imagem, não mudam com isso - ver
    // hypr/scripts/apply-theme.sh). Escolha persistida em
    // State/theme-mode.json via Styles.setSchemeType, mesmo arquivo do
    // toggle "Cores do wallpaper" logo abaixo.
    readonly property var schemeTypes: [
        { value: "scheme-content", label: "Content" },
        { value: "scheme-expressive", label: "Expressive" },
        { value: "scheme-fidelity", label: "Fidelity" },
        { value: "scheme-fruit-salad", label: "Fruit Salad" },
        { value: "scheme-monochrome", label: "Monochrome" },
        { value: "scheme-neutral", label: "Neutral" },
        { value: "scheme-rainbow", label: "Rainbow" },
        { value: "scheme-tonal-spot", label: "Tonal Spot" },
        { value: "scheme-vibrant", label: "Vibrant" }
    ]

    function pickSchemeType(value) {
        Styles.setSchemeType(value)
        // Mesma lógica do toggle "Cores do wallpaper" abaixo: reaplica na
        // hora com o wallpaper atual, em vez de esperar a próxima troca.
        if (root.current) root.run(["bash", root.scriptsDir + "/apply-theme.sh", root.current])
    }

    // Claro/escuro pras cores derivadas do wallpaper - "--mode" do matugen
    // (só esses 2 valores, ver `matugen --help`). Separado do "Estilo de
    // cor" (--type) acima: um escolhe o ALGORITMO de harmonização, este
    // escolhe se o resultado fica claro ou escuro.
    readonly property var colorModes: [
        { value: "dark", label: "Escuro" },
        { value: "light", label: "Claro" }
    ]

    function pickColorMode(value) {
        Styles.setColorMode(value)
        if (root.current) root.run(["bash", root.scriptsDir + "/apply-theme.sh", root.current])
    }

    // Um Flickable só pra TUDO (botões + estilo de cor + claro/escuro +
    // grade de wallpapers), não só a grade - antes só a grade rolava
    // (Layout.fillHeight própria), e como os botões acima são fixos,
    // sobrava pouquíssima altura pra grade de verdade numa janela do
    // tamanho padrão (piorava ainda mais se a janela fosse redimensionada
    // menor). Mesmo padrão do ColorCustomizer.qml (aba "Personalizar").
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Styles.spacing

                Button {
                    text: "Anterior"
                    primary: false
                    onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "prev"])
                }

                Button {
                    text: "Aleatório"
                    onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "random"])
                }

                Button {
                    text: "Próximo"
                    primary: false
                    onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "next"])
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Cores do wallpaper"
                    color: Styles.foreground
                    font.pixelSize: 12
                    font.family: Styles.fontFamily
                }

                Switch {
                    checked: Styles.useWallpaperColors
                    onToggled: {
                        const next = !Styles.useWallpaperColors
                        Styles.setUseWallpaperColors(next)
                        // Sync immediately instead of waiting for the next wallpaper change.
                        if (next && root.current) root.run(["bash", root.scriptsDir + "/apply-theme.sh", root.current])
                    }
                }
            }

            Text {
                text: "Estilo de cor"
                color: Styles.foreground
                font.pixelSize: 12
                font.family: Styles.fontFamily
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: Styles.spacing

                Repeater {
                    model: root.schemeTypes

                    Button {
                        required property var modelData

                        text: modelData.label
                        primary: Styles.schemeType === modelData.value
                        onClicked: root.pickSchemeType(modelData.value)
                    }
                }
            }

            Text {
                text: "Claro ou escuro"
                color: Styles.foreground
                font.pixelSize: 12
                font.family: Styles.fontFamily
                font.bold: true
            }

            RowLayout {
                spacing: Styles.spacing

                Repeater {
                    model: root.colorModes

                    Button {
                        required property var modelData

                        text: modelData.label
                        primary: Styles.colorMode === modelData.value
                        onClicked: root.pickColorMode(modelData.value)
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // "interactive: false" + altura própria (contentHeight, em vez
            // de Layout.fillHeight) - sem isso essa GridView tentaria rolar
            // por conta própria DENTRO do Flickable de fora, competindo
            // pelo mesmo gesto de scroll. Assim ela só renderiza todos os
            // wallpapers na altura que precisar, e quem rola de verdade é
            // sempre o Flickable de fora.
            GridView {
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                clip: true
                cellWidth: 132
                cellHeight: 82
                model: FolderListModel {
                    folder: "file://" + root.wallpapersDir
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                delegate: Item {
                    width: 124
                    height: 74

                    required property string filePath
                    required property url fileUrl

                    Rectangle {
                        anchors.fill: parent
                        radius: Styles.radiusSmall
                        color: Styles.surfaceAlt
                        border.width: filePath === root.current ? 2 : 0
                        border.color: Styles.accent
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: parent.border.width
                            source: fileUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 132
                            sourceSize.height: 82
                        }
                    }

                    TapHandler {
                        onTapped: root.run(["bash", root.scriptsDir + "/set-wallpaper.sh", filePath])
                    }
                }
            }
        }
    }
}
