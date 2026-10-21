import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Dashboard

// ============================================================================
// O painel central de controles do shell (Fase 3 da migração Rumda → ZeroShell).
// ============================================================================
//
// POR QUE DEIXOU DE SER "PanelWindow":
//
// Uma PanelWindow é uma superfície layer-shell de BARRA/PANEL. Ela não tem
// "keyboardFocus" no Quickshell 0.3.2 - inspecionando o tipo instalado
// (/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes, componente
// "PanelWindow", linhas 131-201), as propriedades de superfície são
// aboveWindows, anchors, exclusionMode, exclusiveZone, focusable e margins.
// O "focusable" é um booleano: ele diz que a superfície PODE receber foco,
// mas não existe com ela um pedido de foco exclusivo de teclado.
//
// Sem foco exclusivo, o Dashboard aberto não consegue ler o ESC de forma
// confiável (a tecla vai para a janela que estiver focada por baixo, e o
// painel é uma camada que não "pega" o teclado). O atalho Escape do
// LauncherWindow.qml funciona por um motivo específico e não transferível: lá
// o foco está dentro de um TextInput, e é o TextInput que recebe a tecla.
//
// WlrLayershell (Quickshell.Wayland) tem o que é preciso, confirmado no
// qmltypes instalado
// (Quickshell/Wayland/_WlrLayerShell/quickshell-wayland-layershell.qmltypes):
//   layer         : WlrLayer.{Background, Bottom, Top, Overlay}
//   keyboardFocus : WlrKeyboardFocus.{None, Exclusive, OnDemand}
//   anchors/margins/exclusiveZone/exclusionMode/aboveWindows/focusable
// É o mesmo mecanismo que o Rumda usa
// (rumda/common/quickshell/dark/widgets/Dashboard.qml:53-67) e a mesma técnica
// do WlSessionLock que o LockScreen do ZeroShell já usa. A troca é o que
// permite ESC e clique-fora funcionarem.
//
// DIFERENÇA EM RELAÇÃO AO RUMDA (deliberada):
//   - O Rumda anima o "y" do card lendo Screen.height de QtQuick.Window e
//     posiciona com uma conta "(screenH - dashHeight) * 0.5". Aqui a posição
//     de repouso é calculada a partir da ALTURA REAL da superfície
//     (root.height, que o compositor dá), então o painel fica centrado em
//     qualquer resolução/escala, sem número de tela copiado de lugar nenhum.
//   - O Rumda abre/fecha por um FIFO em /tmp. Aqui quem manda é o IpcHandler
//     do DashboardState (o mesmo mecanismo que os scripts do shell já usam).
//   - O Rumda deixa a superfície mapeada no fecho; aqui o teclado é devolvido
//     ao compositor no instante em que "open" vira false (ver keyboardFocus).
//
// ANIMAÇÃO: de baixo para o centro da tela. Quem calcula a curva, a duração e
// o "quanto tempo fica visível depois de fechar" é o Widgets/PanelAnim.qml, o
// mesmo componente que todos os outros painéis do shell já usam - reaproveitar
// é deliberado, para que Configurações > Aparência > Animações
// (Motion.animationType) continue valendo para o Dashboard e nenhum sistema de
// animação paralelo apareça. A aplicação do valor no card é feita por um
// Translate (ver o comentário do centerBox, que explica por que centralizar e
// deslizar não podem sharingar a mesma propriedade).
//
// CONTEÚDO: as 4 abas do ZeroShell (Início / Player / Sistema / Ajustes) foram
// preservadas - elas concentram recursos que não têm equivalente no Rumda
// (histórico de notificações, calendário, player MPRIS, métricas do sistema,
// toggles rápidos). O que o Rumda tem e aqui faltava - brilho e um bloco de
// perfil/energia dentro do painel - entrou na aba Início como
// DashBrightness.qml e DashProfilePower.qml.
// ============================================================================
WlrLayershell {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Overlay: acima de tudo, inclusive das janelas normais. É a camada certa
    // para um painel modal que sequestra o foco.
    layer: WlrLayer.Overlay

    color: "transparent"

    // O painel não reserva espaço na tela (exclusionMode Ignore numa camada
    // Overlay não gera exclusive zone de verdade), então o Hyprland nunca tenta
    // contornar nada por causa dele.
    exclusionMode: ExclusionMode.Ignore

    readonly property string debugShellScript: Quickshell.env("HOME") + "/.config/hypr/scripts/debug-shell.sh"
    readonly property string debugShellVideoScript: Quickshell.env("HOME") + "/.config/hypr/scripts/debug-shell-video.sh"

    // ---- Foco de teclado ----
    // LIGADO no instante em que "open" vira true e DESLIGADO no instante em
    // que vira false - ou seja, o teclado volta pro compositor assim que o
    // fechamento COMEÇA, e não quando a animação acaba. Isso é intencional e é
    // um ganho sobre o Rumda: durante a animação de saída o painel ainda está
    // desenhado (é bonito ver sair), mas já não engole tecla nenhuma, então
    // digitar no app que estiver embaixo durante esse quarto de segundo
    // funciona.
    //
    // "focusable" acompanha: sem ele, a superfície não pode receber foco.
    keyboardFocus: DashboardState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: DashboardState.open

    // "anim.shouldBeVisible" e NUNCA "DashboardState.open" direto: é o que dá
    // tempo da animação de saída rodar antes de a superfície desmapear (ver o
    // comentário longo de "shouldBeVisible" em Widgets/PanelAnim.qml, que
    // explica o problema de mapear/desmapar disparar a animação de layer do
    // Hyprland por baixo da nossa).
    // Distância do slide. Precisa ser maior que "metade da tela + metade do card"
        // para que o card saia INTEIRO pela borda de baixo: o topo dele chega a
        // "centro + distance", e para não sobrar nenhum pixel dentro da tela é
        // preciso distance >= (surfaceHeight/2) + (altura/2). Medido com a tela
        // de 768: 384 + 282 = 666px, e aqui vai 728 - folga de 62px. Derivar da
        // altura real da superfície (e não de um número fixo) é o que mantém o
        // painel corretamente escondido em qualquer resolução.
        PanelAnim {
            id: anim
            open: DashboardState.open
            edge: "bottom"
            distance: root.surfaceHeight / 2 + root.maxTabHeight + 62
        }

    visible: anim.shouldBeVisible

    // ---- Máscara de entrada ----
    // Aberta: a área sensível é a tela INTEIRA (clickOutside), senão o clique
    // na parte transparente em volta do card cairia no Hyprland e fecharia
    // janelas de baixo em vez de fechar o painel.
    //
    // Fechando: encolhe para o próprio card. Durante a cauda da animação de
    // saída não precisamos mais detectar clique-fora (já está fechando), e uma
    // superfície tela-inteira ainda mapeada não pode ficar roubando clique do
    // que estiver embaixo. Mesmo idioma do PowerMenu.qml:63.
    mask: Region { item: DashboardState.open ? clickOutside : card }

    // ---- Medidas ----
    // Alturas por aba: só o card (um Item comum, barato) muda de tamanho; a
    // superfície em si nunca é redimensionada, o que evita o engasgo/serrilha
    // que aparecia quando a superfície Wayland era redimensionada a cada frame.
    // Alturas por aba: só o card (um Item comum, barato) muda de tamanho; a
    // superfície em si nunca é redimensionada, o que evita o engasgo/serrilha
    // que aparecia quando a superfície Wayland era redimensionada a cada frame.
    //
    // "home" subiu de 420 para 565 na Fase 3 porque a coluna esquerda ganhou
    // dois cards (DashBrightness + DashProfilePower, 108 cada) abaixo do
    // calendário. Medido: a coluna passou a pedir ~472px, e o card precisa
    // ainda de 32 de margem + 36 do cabeçalho + espaçamentos + divisória = 565.
    // Com a tela em 768 de altura o card centralizado ocupa de 101 a 666, ou
    // seja, cabe sem encostar nas bordas. As outras abas não mudaram.
    readonly property var tabHeights: ({
        home: 565,
        player: 260,
        system: 430,
        quick: 390
    })
    readonly property var currentSize: ({ w: DashboardState.cardWidth, h: tabHeights[tabs.current] || tabHeights.home })
    readonly property int maxTabHeight: Math.max(tabHeights.home, tabHeights.player, tabHeights.system, tabHeights.quick)

    // Margem inferior que põe o card no CENTRO vertical da tela - calculada a
    // partir da altura real da superfície (root.height) e da altura MÁXIMA do
    // card. Usar a máxima e não a atual evita o card "andar" enquanto troca de
    // aba (a altura dele anima, e uma margem dependente da altura atual
    // animaria junto, pendulando).
    //
    // "surfaceHeight" com fallback em Screen.height: a superfície ancorada nos
    // quatro lados tem a altura da saída, mas há uma janela curta em que o
    // proxy ainda reporta 0 (antes de a geometria ser resolvida). Se isso
    // vazasse para a conta, a margem viraria 0 e o card apareceria colado na
    // borda inferior num quadro ou dois. Screen.height é a altura real do
    // output reportada pelo Qt, então o fallback não é um número chutado - é o
    // mesmo valor, de outra fonte.
    readonly property real surfaceHeight: root.height > 0 ? root.height : Screen.height

    // ---- Clique fora fecha ----
    // Fica ATRÁS do card (o card vem depois na árvore = z maior), e o card tem
    // o próprio MouseArea de preenchimento (mais abaixo, dentro do Rectangle)
    // que absorve cliques internos - sem ele, um clique numa área vazia do card
    // passaria direto e fecharia o painel, que é justamente o que não deve
    // acontecer. Mesmo truque do PowerMenu.qml:133.
    MouseArea {
        id: clickOutside
        anchors.fill: parent
        onClicked: DashboardState.setOpen(false)
    }

    // ESC funciona independentemente de onde esté o foco dentro do painel: o
    // FocusScope recebe o evento antes dos filhos, porque é o pai na cadeia de
    // foco e o foco do item ativo acaba propagando pra ele quando nenhum
    // tratamento mais específico aceita. Por isso não depende do item focado.
    FocusScope {
        id: scope
        anchors.fill: parent
        focus: DashboardState.open

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                DashboardState.setOpen(false)
                event.accepted = true
            }
        }

        // Dupla proteção: o Keys handler acima é o caminho normal, mas
        // atalhos por padrão do Qt (QShortcut/StandardKey) podem consumir o
        // ESC antes de ele chegar nas Keys. Este Shortcut vive no mesmo
        // FocusScope, então respeita o mesmo foco - e como o painel tem foco
        // EXCLUSIVO enquanto aberto, um ESC no painel não pode cair no atalho
        // "sair da sessão" do Hyprland.
        //
        // "sequences" (plural) e não "sequence": StandardKey.Cancel associa mais
        // de uma tecla (no Qt, Escape e mais), e com "sequence" o Qt liga só
        // uma delas e avisa - foi exatamente o que apareceu ao carregar:
        //   WARN scene: QML Shortcut ... Only binding to one of multiple key
        //   bindings associated with 70. Use 'sequences: [ <key> ]'
        Shortcut {
            sequences: [StandardKey.Cancel]
            onActivated: DashboardState.setOpen(false)
        }

        // ====================================================================
        //=centerBox: centraliza o card e carrega o deslocamento da animação
        // ====================================================================
        // São dois cuidados que não podem morar no mesmo "y":
        //
        //  1. CENTRALIZAR PELA ALTURA ATUAL. Ancorar o card por
        //     anchors.bottom + bottomMargin e calcular essa margem com a altura
        //     MÁXIMA (565) centralizava bem a aba mais alta, mas deixava as
        //     mais baixas 67px abaixo do centro - medido ao vivo com a aba
        //     Sistema (430): card entre 236 e 666 em vez de 169 e 599. Com a
        //     altura ATUAL a centralização é exata em toda aba.
        //
        //  2. NÃO COLIDIR AS DUAS ANIMAÇÕES. Se a centralização usasse
        //     anchors.bottomMargin com Behavior, esse Behavior dispararia
        //     tanto na troca de aba (a altura anima em durationSlow) quanto no
        //     abrir/fechar (o slide), e o painel passaria a "pendular" quando
        //     mudasse de aba, porque a margem correria atrás da altura.
        //
        // A solução: o "y" do centerBox centraliza e NÃO tem Behavior nenhum -
        // ele acompanha de perto a animação da altura do card, que já é suave.
        // O slide fica num Translate, que é um deslocamento puramente visual:
        // não mexe em layout, não disputa com o y, e tem o seu próprio Behavior
        // na duração do slide (durationNormal, igual aos outros painéis).
        Item {
            id: centerBox

            anchors.horizontalCenter: parent.horizontalCenter
            width: card.width
            height: card.height
            y: Math.max(0, (root.surfaceHeight - card.height) / 2)

            transform: Translate {
                // slideOffset é NEGATIVO quando fechado (por convenção do
                // PanelAnim), então o sinal é invertido aqui para o card
                // descer para baixo da tela em vez de subir.
                y: -anim.slideOffset
            }

            // Shadow DENTRO do centerBox, e não como irmão dele: o
            // MultiEffect faz "anchors.fill: target", e o Qt só permite ancorar
            // em item que seja pai ou IRMÃO. Quando o card foi para dentro do
            // centerBox, deixar o Shadow aqui fora virou um neto e o compositor
            // avisava a cada carga:
            //   WARN scene: QML Shadow ... Cannot anchor to an item that isn't
            //   a parent or sibling.
            Shadow { target: card }

            Rectangle {
                id: card

                width: root.currentSize.w
                height: root.currentSize.h
                radius: Styles.radiusShell
                color: Styles.background
                border.color: Styles.border
                border.width: 2

                opacity: anim.targetOpacity
                scale: anim.targetScale
                transformOrigin: Item.Bottom

            // durationNormal (não durationFast) de propósito - tem que
            // acompanhar a duração do slide (o Translate do centerBox,
            // que também é durationNormal, vindo do PanelAnim): se a
            // opacidade chegasse a 0 mais rápido que o
            // slide termina, o card ficaria invisível ainda no meio do
            // movimento, e a sensação era de "sumiu com fade" em vez de
            // "deslizou pra fora" (a segunda metade do deslize acontecia sem
            // ninguém ver).
            Behavior on opacity { NumberAnimation { duration: Motion.durationNormal } }
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
            // mais fluida do que a ease-in-out simples. Esta é a animação de
            // tamanho; o slide abrir/fechar é o Translate do centerBox.
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

            // Clique DENTRO do card não fecha. Este MouseArea é declarado
            // antes do conteúdo, então fica embaixo dele na ordem de z: os
            // controles (que têm TapHandler/Handler/Button) continuam
            // recebendo o clique normalmente, e só a área que ninguém trata
            // cai neste MouseArea, que absorve sem fazer nada.
            MouseArea { anchors.fill: parent }

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
                        // (uns 20s, ~2s x 10 passos) - o ícone gira enquanto isso,
                        // mesma ideia do botão de câmera.
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
                    // Só instancia o conteúdo com o painel aberto (igual à versão anterior):
                    // as abas nascem junto com a abertura e morrem no
                    // fechamento, então nada fica rodando por trás de um painel
                    // fechado.
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
            }   // fim do card
        }       // fim do centerBox

        Component { id: homeTabComp; HomeTab {} }
        Component { id: playerTabComp; PlayerTab {} }
        Component { id: systemTabComp; SystemTab {} }
        Component { id: quickTabComp; QuickSettingsTab {} }
    }
}