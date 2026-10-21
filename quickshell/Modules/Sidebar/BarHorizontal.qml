import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Dashboard
import qs.Modules.Sidebar.RumdaBarModules

// Conteúdo da barra na HORIZONTAL (posição "top"/"bottom" em Configurações >
// Barra). A versão vertical usa os módulos "de tile" do Rumda (28x45, 28x78),
// que são altos demais pra uma barra de 48px - aqui tudo é uma LINHA única
// (ícone + texto do lado), com a altura travada em rowHeight.
//
// Montagem: três blocos - esquerda (relógio, volume, CPU) colada na borda,
// workspaces no centro e ações na direita. Os três são posicionados com
// ANCORA, não com elástico de Layout: com elástico o centro só fica no meio
// se os dois lados tiverem exatamente a mesma largura, e aqui eles não têm
// (o lado esquerdo é bem mais largo). Já "anchors.horizontalCenter" coloca no
// meio da barra sem depender de conta nenhuma.
Item {
    id: bar

    // Altura de TODOS os itens, tirada dos tokens do Styles (control = 30):
    // a barra tem 48px e o Loader tira Styles.spacing (4) de cada lado, então
    // sobra folga e o item fica centralizado. Aplicada em preferred E maximum,
    // porque um Layout respeita o maior - é o que impede um item de "sair" da
    // barra. Também é a medida dos TileButton e do tile do clima, então
    // todo botão da barra tem exatamente o mesmo tamanho.
    readonly property int rowHeight: Styles.control

    property real temperature: 0

    // Botão de Wi-Fi do shell, injetado pelo SidebarNew (mesmo esquema do
    // "profileComponent" da TopSection: o WifiButton vive em
    // "qs.Modules.Sidebar", que importa a barra - importar de volta aqui
    // seria ciclo).
    property Component wifiComponent

    // ---- Volume (Pipewire) ----
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool volumeReady: !!(sink && sink.ready && sink.audio)
    readonly property bool muted: volumeReady && sink.audio.muted

    // ================= Lado esquerdo =================
    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Styles.spacing

        // ---- Relógio ----
        // O ClockModule do Rumda empilha hora e minuto ("12" em cima de "53"),
        // que é o jeito certo num tile vertical de 30x45 mas fica espremido
        // aqui. Este é o mesmo relógio numa linha, com a data embaixo, e o
        // clique continua mandando a notificação com a data.
        Rectangle {
            id: clockTile

            // Interruptores da página "Barra" das Configurações - na vertical
            // quem lê esses mesmos flags é a TopSection/CenterSection/
            // BottomSection.
            visible: SidebarConfig.showClock

            // Sem "readonly": o Timer abaixo reatribui pra atualizar (um
            // binding seria reescrito e a hora ficaria congelada).
            property var now: new Date()

            Layout.preferredWidth: clockCol.implicitWidth + Styles.spacing * 2
            Layout.preferredHeight: bar.rowHeight
            Layout.maximumHeight: bar.rowHeight
            radius: Styles.radiusSmall
            color: Styles.surface
            border.width: 1
            border.color: Styles.border

            // Reconta a cada 10s: só os minutos aparecem, e recriar o Date é
            // barato (o "new Date()" do binding já dá a hora atual).
            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: clockTile.now = new Date()
            }

            Column {
                id: clockCol
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: Qt.formatTime(clockTile.now, "hh:mm")
                    color: Styles.accent
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeNormal
                    font.bold: true
                }

                Text {
                    text: Qt.formatDate(clockTile.now, "ddd, d MMM")
                    color: Styles.foregroundMuted
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeSmallest
                }
            }

            // Mesma mensagem que o ClockModule do Rumda mandava ao clicar.
            // Fica fora do MouseArea porque não se declara um objeto QML
            // dentro de um bloco JS - o clique só liga o "running".
            Process {
                id: dateNotify
                running: false
                command: [
                    "notify-send",
                    Qt.formatDate(clockTile.now, "dddd, d MMMM yyyy"),
                    Qt.formatTime(clockTile.now, "hh:mm AP")
                ]
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: dateNotify.running = true
            }
        }

        // ---- Volume: ícone + barra + porcentagem ----
        // Os itens com tamanho próprio (Icon, Text, Slider) ficam só com o
        // AlignVCenter: forçar preferredHeight/maximumHeight neles esticava o
        // ícone na vertical (ele é quadrado, 16x16, e o Layout esticava só a
        // altura, deixando o desenho achatado).
        Icon {
            id: volumeIcon
            visible: SidebarConfig.showVolume
            Layout.alignment: Qt.AlignVCenter
            icon: bar.muted ? "speaker-dark" : "speaker"
            size: Styles.controlIcon
            tint: bar.muted ? Styles.foregroundMuted : Styles.foreground
        }

        Slider {
            visible: SidebarConfig.showVolume
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 90
            value: bar.volumeReady ? bar.sink.audio.volume : 0
            onMoved: (v) => { if (bar.volumeReady) bar.sink.audio.volume = v }
        }

        Text {
            visible: SidebarConfig.showVolume
            Layout.alignment: Qt.AlignVCenter
            text: bar.volumeReady ? (bar.muted ? "—" : Math.round(bar.sink.audio.volume * 100) + "%") : ""
            color: Styles.foregroundMuted
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmall
        }

        // ---- CPU / RAM: os mesmos anéis, lado a lado ----
        RowLayout {
            visible: SidebarConfig.showCpu
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: bar.rowHeight
            Layout.maximumHeight: bar.rowHeight
            spacing: Styles.spacing / 2

            RadialIndicator {
                percent: SystemStats.cpuPercent
                indicatorColor: Styles.accent
                backgroundColor: Styles.surfaceAlt
                size: Styles.controlRing
            }

            RadialIndicator {
                percent: SystemStats.ramPercent
                indicatorColor: Styles.accentAlt
                backgroundColor: Styles.surfaceAlt
                size: Styles.controlRing
            }
        }

        Text {
            visible: SidebarConfig.showCpu
            Layout.alignment: Qt.AlignVCenter
            text: SystemStats.cpuPercent + "%"
            color: Styles.foregroundMuted
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmallest
        }
    }

    // ================= Workspaces (centro) =================
    // Duas correções em relação à primeira versão:
    //
    // 1) "Hyprland.workspaces.values" (o array) e não "Hyprland.workspaces"
    //    (o modelo). Com o modelo, o Quickshell recria os proxies a cada
    //    evento e a "Behavior" não roda: a pílula pulava de 9 para 44 num
    //    único passo. O Modules/Sidebar/Workspaces.qml do próprio shell já usa
    //    o array - é por isso que o indicador dele anima.
    //
    // 2) Cada workspace ocupa uma CÉLULA de largura fixa (22px) e a pílula
    //    cresce DENTRO dela, centralizada. Antes a pílula mudava de tamanho
    //    dentro da linha e atravessava a vizinha enquanto empurrava as outras.
    //    Com a célula fixa ninguém precisa ser empurrado: a pílula cresce
    //    no lugar e desliza.
    Row {
        id: wsRow

        // Espaço reservado por workspace na linha: um tile menos a folga dos
        // dois lados, para o passo das pílulas bater com a medida dos botões.
        readonly property int cellWidth: Styles.control - Styles.spacing * 2

        visible: SidebarConfig.showWorkspaces
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: Hyprland.workspaces.values

            delegate: Item {
                required property var modelData

                width: wsRow.cellWidth
                height: bar.rowHeight

                // Fundo de hover: avisa que ali é clicável (a pílula é
                // pequena demais pra ser o alvo do clique sozinha).
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 2
                    height: parent.height - (bar.rowHeight - Styles.controlPill)
                    radius: Styles.radiusFull
                    color: hover.hovered ? Styles.surfaceAlt : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: modelData.focused ? 18
                         : (modelData.active ? 12 : 8)
                    height: Styles.controlPill
                    radius: Styles.radiusFull
                    color: modelData.focused ? Styles.workspaceFocused
                         : (modelData.active ? Styles.workspaceActive
                         : "transparent")
                    border.width: modelData.focused || modelData.active ? 0 : 1
                    border.color: Styles.border

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                HoverHandler { id: hover }

                TapHandler {
                    // Este Hyprland (hyprland.lua) lê o dispatch como Lua: a
                    // sintaxe "workspace <id>" falha em silêncio, tem que ser
                    // a chamada hl.dsp - igual ao Modules/Sidebar/
                    // Workspaces.qml.
                    onTapped: Hyprland.dispatch("hl.dsp.focus({workspace = " + modelData.id + "})")
                }
            }
        }
    }

    // ================= Lado direito =================
    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Styles.spacing

        // ---- Clima ----
        // Era o WeatherStatus do Rumda: tile de 28x48 com o ícone EM CIMA da
        // temperatura (uma coluna) - o "26°" ficava para fora do fundo da
        // barra. Aqui a mesma informação numa linha só, com a mesma fonte
        // (wttr.in) e o mesmo intervalo do Rumda.
        Process {
            id: weatherProcess
            running: true
            command: ["curl", "-s", "https://wttr.in/?format=%t"]

            stdout: SplitParser {
                onRead: temp => {
                    bar.temperature = parseFloat(temp.replace(/[^\d.-]/g, ""))
                }
            }
        }

        Timer {
            interval: 1000000
            running: true
            repeat: true
            onTriggered: weatherProcess.running = true
        }

        // Mesmo tile dos outros botões (mesma altura, mesma borda), só mais
        // largo por causa do texto - antes ficava solto, sem caixa nenhuma,
        // ao lado de três botões com borda.
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: bar.rowHeight
            Layout.maximumHeight: bar.rowHeight
            Layout.preferredWidth: weatherRow.implicitWidth + Styles.spacing * 2
            Layout.maximumWidth: Layout.preferredWidth
            radius: Styles.radiusSmall
            // "surfaceAlt" é o idleColor padrão do TileButton - é a cor dos
            // outros botões da barra (tema e power). Com "transparent" o tile
            // ficava mais escuro que os vizinhos.
            color: Styles.surfaceAlt
            border.width: 1
            border.color: Styles.border

            Row {
                id: weatherRow
                anchors.centerIn: parent
                spacing: Styles.spacing / 2

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "weather"
                    size: Styles.controlIcon
                    tint: Styles.accentAlt
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // "—" até o wttr.in responder (evita o "0°" inicial).
                    text: bar.temperature ? `${bar.temperature}°` : "—"
                    color: Styles.foreground
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeNormal
                    font.bold: true
                }
            }
        }

        TileButton {
            visible: SidebarConfig.showTheme
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumHeight: bar.rowHeight
            icon: "theme-switch"
            size: Styles.control
            iconSize: Styles.controlIcon
            showBorder: true
            onClicked: Styles.applyColorMode(Styles.colorMode === "dark" ? "light" : "dark")
        }

        // Wi-Fi: o mesmo WifiButton.qml do shell usado na barra vertical
        // (ícone por faixa de sinal + toggle pra aba Wi-Fi das Configurações),
        // não um botão de ícone fixo. O "Icon" com "wifi" que estava aqui
        // mentia: mostrava "conectado" mesmo sem rede nenhuma.
        Rectangle {
            id: wifiTile
            visible: SidebarConfig.showWifi
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: bar.rowHeight
            Layout.preferredHeight: bar.rowHeight
            Layout.maximumWidth: bar.rowHeight
            Layout.maximumHeight: bar.rowHeight
            radius: Styles.radiusSmall
            // "surfaceAlt" é o idleColor padrão do TileButton - é a cor dos
            // outros botões da barra (tema e power). Com "transparent" o tile
            // ficava mais escuro que os vizinhos.
            color: Styles.surfaceAlt
            border.width: 1
            border.color: Styles.border

            Loader {
                anchors.centerIn: parent
                sourceComponent: bar.wifiComponent
                width: parent.width
                height: parent.height
            }
        }

        TileButton {
            visible: SidebarConfig.showPower
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumHeight: bar.rowHeight
            icon: "shutdown"
            size: Styles.control
            iconSize: Styles.controlIcon
            showBorder: true
            onClicked: Visibility.powerMenuOpen = !Visibility.powerMenuOpen
        }
    }
}