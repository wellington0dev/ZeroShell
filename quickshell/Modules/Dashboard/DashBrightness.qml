import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

// ============================================================================
// Controle de brilho do Dashboard (Fase 3).
// ============================================================================
//
// POR QUE EXISTE: o shell não tinha controle de brilho em nenhum módulo - a
// busca por "brightness" em todos os .qml do ZeroShell não retorna nada, e
// não existe script de brilho em ~/.config/hypr/scripts. O Rumda tem um
// (dark/widgets/DashBrightnessControl.qml) que conversa com o brilho por
// "brightnessctl" e/ou "ddcutil".
//
// DECISÃO DE ARQUITETURA (medida antes de escrever):
//   - Só "brightnessctl" está instalado nesta máquina (/usr/bin/brightnessctl);
//     "light" e "ddcutil" não existem. Implementar a bifurcação do Rumda seria
//     código morto aqui, então fica só o caminho que funciona.
//   - O único backlight exposto é /sys/class/backlight/intel_backlight. O
//     "backlight" do brightnessctl aponta pra ele. Se a máquina não tiver
//     backlight nenhum (tablet com brilho só por software, por exemplo), o
//     painel mostra "indisponível" em vez de fingir que funciona.
//
// O QUE NÃO FOI REUTILIZADO DO RUMDA: o Rumda faz três Process por passo de
// brilho (sonda "brightnessctl -c backlight info", "set 10%+", leitura do valor
// atual com grep -oP). Aqui é uma coisa só: lê o valor absoluto uma vez e
// escreve o novo valor absoluto, o que evita a dependência de "ddcutil" e o
// grep com expressão regular frágil. Também não há slider: um slider de brilho
// que solta um comando por pixel arranhado é uncomfortable de acertar; dois
// passos fixos de 5% são previsíveis.
//
// MODO SOMENTE-LEITURA (readOnly): com true, o componente lê o brilho e mostra
// o valor, mas QUALQUER tentativa de mudar é ignorada. Existe para a validação
// da Fase 3 - dá para conferir a integração, a leitura do dispositivo e o
// desenho sem mexer na iluminação da tela do usuário. Fora da validação ele
// fica false e o controle funciona normal.
Rectangle {
    id: root

    // Ver comentário acima. Só para teste; o Dashboard sempre usa false.
    property bool readOnly: false

    // Passo de cada clique, em porcentagem.
    readonly property int step: 5

    // "N/D" enquanto não se sabe ler o dispositivo (e se nunca der). Evita
    // mostrar 0% (que parece "apagado") quando é só "não li ainda".
    readonly property bool available: percent >= 0

    property int percent: -1

    radius: Styles.radiusShell
    color: Styles.surface
    border.color: Styles.border
    border.width: 1

    Layout.fillWidth: true
    Layout.preferredHeight: 108

    // ---- Leitura ----
    // Um Process só, com SplitParser. Roda no Component.onCompleted e depois
    // de cada escrita, para o valor exibido acompanhar o que o hardware
    // realmente aplicou (e não só o que pedimos).
    Process {
        id: readProcess
        // Leitura por "info" e não por "get": nesta maquina (Arch, intel_backlight)
        // "brightnessctl -c backlight get" devolve o valor BRUTO solto ("7199"),
        // enquanto "info" traz a linha "Current brightness: 7199 (30%)". Extrair
        // o percentual do "info" funciona tanto aqui quanto em maquinas onde o
        // "get" ja vem em porcentagem - e nao depende de o device se chamar
        // awk e não sed: a linha é "Current brightness: 7199 (30%)", e o sed
        // com grupo de captura precisa de escaping em duas camadas (o "(" do
        // grupo viraria "\(" no shell e "\\(" no QML) e ainda assim falhava
        // com "unmatched )". O awk -F'[(%]' pega o campo entre parênteses e %
        // sem nenhum escape, o que deixa a string segura no literal do QML.
        command: ["bash", "-c", "brightnessctl -c backlight info 2>/dev/null | awk -F'[(%]' '/Current brightness/{print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const v = parseInt(line)
                if (!isNaN(v)) root.percent = v
            }
        }
    }

    function refresh() {
        if (readProcess.running) return
        readProcess.running = true
    }

    // ---- Escrita ----
    // Ignorada de propósito quando readOnly (ver comentário do componente) e
    // quando não se consegue ler o brilho (sem valor de referência não há como
    // calcular o próximo).
    function stepBy(delta) {
        if (root.readOnly) return
        if (!root.available) return
        const next = Math.max(0, Math.min(100, root.percent + delta))
        if (next === root.percent) return

        // "brightnessctl set N%" é a sintaxe de PORCENTAGEM que o próprio
        // binário documenta ("percentage value  Example: 50%"), então escrever o
        // novo valor absoluto em % dispensa converter pela escala do hardware.
        writeProcess.command = ["bash", "-c", "brightnessctl -c backlight set " + next + "% 2>/dev/null"]
        writeProcess.running = true
    }

    Process {
        id: writeProcess
        command: ["bash", "-c", "true"]
        running: false

        stdout: SplitParser { onRead: (line) => {} }
    }

    // Depois de escrever, relê: mostra o que o hardware de fato aceitou (e
    // desfaz a exibição otimista caso o sistema tenha recusado o valor - por
    // exemplo, acima do mínimo do driver).
    Connections {
        target: writeProcess
        function onRunningChanged() {
            if (!writeProcess.running) root.refresh()
        }
    }

    Component.onCompleted: refresh()

    // Sinaliza que o brilho pode ter mudado por fora (outro app, tecla de
    // mídia). Recomeça a sondagem em vez de assumir que o valor continua.
    Connections {
        target: root
        function onVisibleChanged() { if (root.visible) root.refresh() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Brilho"
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.available ? root.percent + "%" : "indisponível"
                color: root.available ? Styles.foreground : Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
            }
        }

        // Barra de nível. A "preenchida" é um Rectangle com width em % do
        // container via Layout, não um scale - assim o Behavior de width anima
        // sem mexer no raio nem esticar as bordas.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Styles.surfaceAlt

            Rectangle {
                id: fill
                height: parent.height
                width: root.available ? parent.width * (root.percent / 100) : 0
                radius: 4
                color: Styles.accent

                Behavior on width {
                    NumberAnimation { duration: Motion.durationFast; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: Motion.durationFast }
                }
            }

            // Escurece conforme apaga - dá para ler o nível sem precisar do
            // número, que é o que o olho faz primeiro num controle de brilho.
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: parent.width * (1 - (root.available ? root.percent / 100 : 0))
                radius: 4
                color: Qt.rgba(0, 0, 0, 0.35)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            // Botões de passo. Text "+"/"−" em vez de IconButton porque o shell
            // não tem ícone de mais/menos em Icons/ (conferido: existem 57 SVGs e
            // nenhum é "plus"/"minus"), e adicionar um ícone só para isto seria
            // mais pesado que o texto. Mesmo visual dos demais botões (fundo no
            // hover, raio do botão) para não destoar.
            component StepButton: Rectangle {
                id: btn
                property string glyph: "−"
                property bool enabled: true

                signal activated()

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: Styles.radiusButton
                color: stepHover.hovered && btn.enabled ? Styles.surfaceAlt : "transparent"
                border.color: Styles.border
                border.width: 1
                opacity: btn.enabled ? 1 : 0.4

                Behavior on color { ColorAnimation { duration: Motion.durationFast } }

                Text {
                    anchors.centerIn: parent
                    text: btn.glyph
                    color: Styles.foreground
                    font.pixelSize: 18
                    font.family: Styles.fontFamily
                }

                // Referenciado pelo ID direto ("stepHover.hovered") e NÃO por
                // "btn.hover.hovered": um HoverHandler é um PointerHandler, não
                // um Item, então ele não entra como propriedade do pai - a
                // forma "pai.hover" dá undefined e o log enche de
                // "Cannot read property 'hovered' of undefined". É o mesmo
                // idioma do DashboardTabs.qml:37.
                HoverHandler { id: stepHover; enabled: btn.enabled }
                TapHandler { enabled: btn.enabled; onTapped: btn.activated() }
            }

            StepButton {
                glyph: "−"
                enabled: root.available && !root.readOnly
                onActivated: root.stepBy(-root.step)
            }

            StepButton {
                glyph: "+"
                enabled: root.available && !root.readOnly
                onActivated: root.stepBy(root.step)
            }
        }
    }
}