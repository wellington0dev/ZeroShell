import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

// O card do dashboard em si: fica fora da tela (acima do topo) até
// DashboardState.open virar true (por causa da DashboardTrigger.qml ou por
// hover no próprio card), aí desliza pra baixo. Mesma técnica de
// "margins.top negativo pra esconder" usada no menu de energia, só que
// centralizado na tela em vez de alinhado à sidebar.
//
// 4 abas (DashboardTabs.qml): Início (relógio + foto + notificações),
// Player (PlayerContent, movido pra cá em vez de ter janela própria),
// Sistema (CPU/RAM/temperatura/rede/bateria) e Ajustes (toggles rápidos).
PanelWindow {
    id: root

    readonly property string debugShellScript: Quickshell.env("HOME") + "/.config/hypr/scripts/debug-shell.sh"
    readonly property string debugShellVideoScript: Quickshell.env("HOME") + "/.config/hypr/scripts/debug-shell-video.sh"

    // Sem isso, a superfície continuaria ocupando o mesmo espaço sempre (só
    // invisível) nos modos de animação "popup"/"fade" - onde margins.top
    // nunca sai de 0 - e roubaria hover/clique de quem tiver perto (mesmo
    // bug real encontrado no VolumePanel.qml antes do PanelAnim existir). No
    // modo "slide" não faz diferença (a janela já ficava fora da tela).
    visible: DashboardState.open

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    // Fixa (não segue card.height reativamente): redimensionar a superfície
    // Wayland de verdade a cada frame da animação de troca de aba é pesado
    // pro compositor e ficava com uma leve serrilhada/engasgo visível. Com
    // altura fixa (a maior entre as abas), só o "card" (um item QML comum,
    // bem mais barato de animar) muda de tamanho - a janela em si nunca
    // muda, só o conteúdo transparente ao redor do card cresce/encolhe.
    implicitHeight: maxTabHeight + 20

    // Tipo/velocidade da animação de abrir/fechar vêm de
    // Configurações > Aparência > Animações (Motion.animationType) - ver
    // Widgets/PanelAnim.qml.
    PanelAnim {
        id: anim
        open: DashboardState.open
        edge: "top"
        distance: root.implicitHeight
    }

    margins.top: anim.slideOffset

    Behavior on margins.top {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standard
        }
    }

    Shadow { target: card }

    // Largura igual nas 3 abas - só a altura muda conforme o conteúdo.
    // (DashboardState.cardWidth pra ficar em um lugar só, já que
    // DashboardTrigger.qml também precisa dessa largura.)
    readonly property var tabHeights: ({
        home: 420,
        player: 260,
        system: 430,
        quick: 220
    })
    readonly property var currentSize: ({ w: DashboardState.cardWidth, h: tabHeights[tabs.current] || tabHeights.home })
    readonly property int maxTabHeight: Math.max(tabHeights.home, tabHeights.player, tabHeights.system, tabHeights.quick)

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Styles.edgeMargin
        width: root.currentSize.w
        height: root.currentSize.h
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        opacity: anim.targetOpacity
        scale: anim.targetScale
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.boing
            }
        }

        // "emphasized" em vez de "standard" e um pouco mais de duração: a
        // curva assinatura do M3 (acelera/desacelera mais suave, sem
        // brusquidão) deixa o redimensionamento entre abas com uma sensação
        // mais fluida do que a ease-in-out simples.
        Behavior on width {
            NumberAnimation {
                duration: Motion.durationSlow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasized
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Motion.durationSlow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasized
            }
        }

        HoverHandler {
            onHoveredChanged: DashboardState.hoveringCard = hovered
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing * 2
            spacing: Styles.spacing * 1.5

            RowLayout {
                Layout.fillWidth: true
                spacing: Styles.spacing

                DashboardTabs {
                    id: tabs
                    Layout.fillWidth: true
                }

                // Separa visualmente da navegação por abas - é uma ação
                // utilitária avulsa, não mais uma aba.
                //
                // Altura FIXA (não Layout.fillHeight) de propósito: esse
                // RowLayout não tem Layout.fillHeight próprio, então sua
                // altura "natural" já vem dos filhos - um filho com
                // fillHeight dentro de um layout sem altura própria definida
                // é um quirk conhecido do QtQuick Layouts que fez a linha
                // inteira "explodir" de tamanho (visto ao vivo: empurrou o
                // conteúdo da aba lá pra baixo, com um vão gigante entre o
                // cabeçalho e o resto).
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: Styles.border
                    opacity: 0.6
                }

                Process { id: debugShellProcess; command: ["bash", root.debugShellScript] }

                // Zera a rotação quando o script termina - sem isto o botão
                // ficava "torto" (parado no meio-giro) até o próximo clique.
                Connections {
                    target: debugShellProcess
                    function onRunningChanged() {
                        if (!debugShellProcess.running) debugButton.rotation = 0
                    }
                }

                IconButton {
                    id: debugButton

                    icon: "camera"
                    size: 28
                    enabled: !debugShellProcess.running
                    // Roda hypr/scripts/debug-shell.sh: audita o visual do
                    // shell inteiro (cada painel individualmente + todos
                    // juntos) num workspace vazio, salva em
                    // ~/Pictures/debug-shell/<data-hora>/. O script demora
                    // uns 8-10s (troca de workspace + abre/fecha cada
                    // painel) - o ícone gira enquanto isso pra ficar claro
                    // que o clique registrou e tá em andamento, não travado.
                    onClicked: debugShellProcess.running = true

                    RotationAnimation on rotation {
                        running: debugShellProcess.running
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }

                Process { id: debugShellVideoProcess; command: ["bash", root.debugShellVideoScript] }

                // Mesma lógica do onRunningChanged do botão de câmera acima -
                // zera a rotação quando o script termina.
                Connections {
                    target: debugShellVideoProcess
                    function onRunningChanged() {
                        if (!debugShellVideoProcess.running) debugVideoButton.rotation = 0
                    }
                }

                IconButton {
                    id: debugVideoButton

                    icon: "video"
                    size: 28
                    enabled: !debugShellVideoProcess.running
                    // Roda hypr/scripts/debug-shell-video.sh: igual ao botão
                    // de câmera, mas grava um vídeo (wf-recorder) passando
                    // ~2s por painel em vez de tirar prints. Demora bem mais
                    // (uns 20s, ~2s x 10 passos) - o ícone gira enquanto
                    // isso, mesma ideia do botão de câmera.
                    onClicked: debugShellVideoProcess.running = true

                    RotationAnimation on rotation {
                        running: debugShellVideoProcess.running
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Styles.border
            }

            // Troca de aba destrói e recria o Loader na hora (sourceComponent
            // muda), o que cortava o conteúdo antigo pro novo de golpe
            // enquanto o card ainda estava no meio da animação de
            // redimensionar - um fade rápido no conteúdo novo disfarça essa
            // troca instantânea e deixa tudo com uma sensação mais contínua.
            Loader {
                id: tabLoader

                Layout.fillWidth: true
                Layout.fillHeight: true
                active: DashboardState.open
                sourceComponent: {
                    switch (tabs.current) {
                        case "player": return playerTabComp
                        case "system": return systemTabComp
                        case "quick": return quickTabComp
                        default: return homeTabComp
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Motion.durationNormal; easing.type: Easing.OutCubic }
                }

                onLoaded: {
                    opacity = 0
                    Qt.callLater(() => { tabLoader.opacity = 1 })
                }
            }
        }
    }

    Component { id: homeTabComp; HomeTab {} }
    Component { id: playerTabComp; PlayerTab {} }
    Component { id: systemTabComp; SystemTab {} }
    Component { id: quickTabComp; QuickSettingsTab {} }
}
