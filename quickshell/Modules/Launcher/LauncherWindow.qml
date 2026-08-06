import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Theme
import qs.State
import qs.Widgets

PanelWindow {
    id: root

    IpcHandler {
        target: "launcher"

        // Bound to the Hyprland keybind that used to open rofi:
        // qs ipc call launcher toggle
        function toggle(): void {
            Visibility.launcherOpen = !Visibility.launcherOpen
        }
        // open/close explícitos (além do toggle acima) - scripts que
        // precisam de estado determinístico (ex.: debug-shell.sh) não podem
        // usar um toggle cego sem saber o estado atual antes.
        function open(): void { Visibility.launcherOpen = true }
        function close(): void { Visibility.launcherOpen = false }
    }

    property string query: ""
    property int selectedIndex: 0

    readonly property var results: {
        const apps = DesktopEntries.applications.values
        let list = apps
        if (query.length > 0) {
            const q = query.toLowerCase()
            list = apps.filter(a =>
                (a.name && a.name.toLowerCase().includes(q)) ||
                (a.genericName && a.genericName.toLowerCase().includes(q)) ||
                (a.keywords && a.keywords.some(k => k.toLowerCase().includes(q)))
            )
        }
        return list.slice().sort((a, b) => a.name.localeCompare(b.name))
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        close()
    }

    function close() {
        Visibility.launcherOpen = false
    }

    onVisibleChanged: {
        if (visible) {
            query = ""
            selectedIndex = 0
            searchInput.text = ""
            // forceActiveFocus() right as the surface becomes visible can
            // race the compositor still mapping it, silently no-opping and
            // leaving nothing focused (so the next keypress falls through
            // and closes the launcher instead of typing). Um Timer (mesmo
            // 1ms) dá tempo do mapeamento terminar antes de pedir foco.
            focusTimer.start()
        }
    }

    Timer {
        id: focusTimer
        interval: 1
        onTriggered: searchInput.forceActiveFocus()
    }

    // "anim.shouldBeVisible" (NUNCA "Visibility.launcherOpen" direto) -
    // evita desmapear a superfície ANTES do fade/escala de saída terminar -
    // ver comentário em Widgets/PanelAnim.qml.
    visible: anim.shouldBeVisible
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Enquanto genuinamente aberto, a máscara cobre a JANELA INTEIRA
    // (acompanha "clickOutside" abaixo) - precisa disso pro "clique fora
    // fecha o launcher" (MouseArea abaixo) continuar funcionando em
    // qualquer ponto da tela. Só na cauda de fechamento (Visibility.
    // launcherOpen já é false mas "shouldBeVisible" ainda segura a
    // superfície viva pro fade/escala terminar - ver Widgets/PanelAnim.qml)
    // encolhe pra só "card": nesse momento não precisamos mais detectar
    // clique-fora (já tá fechando), e uma superfície tela-inteira ainda
    // mapeada não pode ficar roubando clique de mais nada por baixo.
    mask: Region { item: Visibility.launcherOpen ? clickOutside : card }

    MouseArea {
        id: clickOutside
        anchors.fill: parent
        onClicked: root.close()
    }

    Shadow { target: card }

    // Tipo/velocidade da animação de abrir/fechar vêm de
    // Configurações > Aparência > Animações (Motion.animationType) - ver
    // Widgets/PanelAnim.qml. Ligação declarativa direta com
    // Visibility.launcherOpen (nada de resetar valor e reaplicar depois via
    // Qt.callLater/Timer feito à mão - testado ao vivo com gravação de tela
    // que essa versão manual não anima nada, só salta direto pro valor
    // final).
    //
    // Sem "edge"/"distance": o launcher agora abre CENTRALIZADO na tela
    // (anchors.centerIn no card abaixo), não mais deslizando de uma borda -
    // "slideOffset" precisa de uma margin de borda pra fazer sentido, e
    // centerIn não usa margin nenhuma. Só opacity/scale valem aqui (modos
    // "popup"/"fade" já funcionam assim; modo "slide" vira um fade+scale
    // pra este painel especificamente, sem deslizar).
    PanelAnim {
        id: anim
        open: Visibility.launcherOpen
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        opacity: anim.targetOpacity
        scale: anim.targetScale
        transformOrigin: Item.Center
        width: 480
        height: 420
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.boing
            }
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing * 1.5
            spacing: Styles.spacing

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Styles.radiusInput
                color: Styles.surface
                border.color: searchInput.activeFocus ? Styles.accent : Styles.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 120 } }

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.margins: 10
                    color: Styles.foreground
                    font.pixelSize: 14
                    font.family: Styles.fontFamily
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    onTextChanged: {
                        root.query = text
                        root.selectedIndex = 0
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, root.results.length - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launch(root.results[root.selectedIndex])
                            event.accepted = true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar aplicativos..."
                        color: Styles.foregroundMuted
                        font.pixelSize: 14
                        font.family: Styles.fontFamily
                        visible: searchInput.text.length === 0
                    }
                }
            }

            ListView {
                id: resultsList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.results
                currentIndex: root.selectedIndex
                highlightMoveDuration: 100

                delegate: AppEntry {
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: 48
                    entry: modelData
                    selected: index === root.selectedIndex
                    onActivated: root.launch(modelData)
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.results.length === 0
                text: "Nenhum aplicativo encontrado"
                color: Styles.foregroundMuted
                font.pixelSize: 12
                font.family: Styles.fontFamily
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
