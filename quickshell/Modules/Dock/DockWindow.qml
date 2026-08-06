import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Theme
import qs.Widgets
import qs.State

// Dock de aplicativos, ancorado embaixo, centralizado - um cartão flutuante
// do tamanho do conteúdo (não um painel edge-to-edge tipo a Sidebar).
//
// Dois modos, trocados pelo botão de pin no canto do cartão
// (DockConfig.pinned, persistido em State/dock-config.json):
// - DESFIXADO (padrão): overlay flutuante que NÃO reserva espaço na tela
//   (ExclusionMode.Ignore) - fica revelado quando:
//     a) o mouse passa na faixa sensível de baixo, ou no próprio cartão
//        (mesma ideia do antigo LauncherTrigger.qml, só que a faixa
//        sensível mora dentro desta mesma janela - o dock já ocupa a
//        borda inferior inteira, não precisa de um DockTrigger.qml
//        separado); ou
//     b) não tem nenhuma janela tiled em foco agora (workspace vazio, ou
//        só janela(s) floating focada) - nesse caso não tem risco de
//        cobrir conteúdo de verdade, então fica à mostra sozinho (ver
//        "noTiledWindowFocused" abaixo, via Quickshell.Hyprland).
//   Some de novo assim que QUALQUER uma das condições deixa de valer.
// - FIXADO: sempre visível, reserva espaço de verdade (exclusiveZone) -
//   empurra as janelas de baixo pra cima, igual a Sidebar empurra da
//   esquerda.
//
// Mostra dois grupos misturados numa fileira só, sem separador visual
// entre eles (ver "items" abaixo):
// - Apps FIXADOS (Configurações > aba Dock, DockConfig.pinnedIds) - clicar
//   abre se não estiver rodando, foca se estiver.
// - Apps RODANDO que não estão fixados - some sozinho quando o app fecha
//   (não é "fixado", só aparece emprestado enquanto a janela existir).
//
// Detecção de "rodando" é a mesma técnica de AppTray.qml (protocolo
// wlr-foreign-toplevel via Quickshell.Wayland.ToplevelManager), só que
// genérica pra qualquer app instalado em vez de 3 hardcoded.
PanelWindow {
    id: root

    color: "transparent"

    // Sem isto, a janela inteira (84px de altura, largura da tela toda -
    // ver implicitHeight abaixo) aceita clique mesmo nas partes vazias/
    // transparentes, mesmo com o cartão escondido - layer-shell não fica
    // "clicável só onde tem conteúdo" sozinho, precisa de uma região de
    // input explícita. Sem mask, TUDO que estivesse atrás da faixa de baixo
    // da tela (últimos ~84px) ficava impossível de clicar, cartão visível
    // ou não. A máscara é só a união de "hoverZone" (a faixa de detecção,
    // sempre no lugar) + "bg" (o cartão em si, que quando escondido fica
    // com Y fora da janela - a máscara acompanha e não bloqueia nada ali).
    mask: Region {
        item: hoverZone
        Region {
            item: bg
            intersection: Intersection.Combine
        }
    }

    // Só FIXADO reserva espaço de verdade - desfixado é sempre "Ignore",
    // mesmo revelado por hover (um overlay temporário não deve empurrar
    // janela nenhuma, senão elas ficariam pulando de tamanho toda hora que
    // o mouse passa perto da borda).
    exclusionMode: DockConfig.pinned ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: DockConfig.pinned ? (cardHeight + restMargin) : 0

    readonly property int cardHeight: 64
    readonly property int restMargin: Styles.edgeMargin

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: cardHeight + Styles.edgeMargin * 2

    // "floating" não existe no HyprlandToplevel exposto por
    // Quickshell.Hyprland (só em "lastIpcObject", que na prática fica
    // VAZIO pra janela recém-focada - testado ao vivo: Configurações virou
    // a ativa e "lastIpcObject" não tinha nem "floating" nem "class"
    // dentro). Por isso consulta "hyprctl activewindow -j" direto (mesmo
    // padrão de script-faz-o-trabalho-de-SO usado no resto do shell),
    // disparado só quando o toplevel ativo muda (onActiveToplevelChanged) -
    // não é polling contínuo, só uma consulta por troca de foco.
    property bool noTiledWindowFocused: true

    Process {
        id: activeWindowProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let data = null
                try { data = JSON.parse(this.text.trim() || "null") } catch (e) { data = null }
                // "null" = nenhuma janela ativa (workspace vazio) - conta
                // como "sem tiled em foco" também.
                root.noTiledWindowFocused = (data === null) || !!data.floating
            }
        }
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { activeWindowProc.running = true }
    }

    Component.onCompleted: activeWindowProc.running = true

    // Revelado se: fixado (sempre), OU o mouse está na faixa sensível de
    // baixo, OU o mouse já está em cima do próprio cartão (senão ele
    // sumiria embaixo do cursor assim que a faixa de 10px inicial deixasse
    // de estar coberta pelo cartão revelado), OU não tem janela tiled
    // focada agora.
    readonly property bool revealed: DockConfig.pinned || hoverZone.hovered || cardHover.hovered || root.noTiledWindowFocused

    // Snapshot reativo de toda janela que o Hyprland expõe pelo protocolo
    // wlr-foreign-toplevel, incluindo minimizadas/em segundo plano.
    readonly property var toplevels: ToplevelManager.toplevels.values

    // Mesma ideia de AppTray.qml (comparação por "includes", não igualdade
    // exata - o mesmo app pode ter appId diferente dependendo de como foi
    // instalado, ex.: nativo vs Flatpak) - só que aqui o "agulha" vem do
    // próprio DesktopEntry (startupClass quando existe, senão o id), não
    // hardcoded por app.
    function findToplevel(entry) {
        if (!entry) return null
        const needle = (entry.startupClass || entry.id || "").toLowerCase()
        if (!needle) return null
        return root.toplevels.find(t => t.appId && t.appId.toLowerCase().includes(needle)) ?? null
    }

    // Contador incrementado por conexão EXPLÍCITA nos sinais de troca
    // abaixo, lido dentro do binding de "pinnedEntries" só pra criar uma
    // dependência garantida - não confia só no encadeamento automático de
    // dependências do QML sobre "DesktopEntries.applications.values"
    // (applications é "isPropertyConstant" no qmltypes; o valor em si
    // nunca muda depois de criado, só o CONTEÚDO do model, via
    // "valuesChanged" - teoricamente isso já bastaria, mas é exatamente o
    // tipo de encadeamento que pode se comportar diferente num processo
    // novo/frio do que depois de um hot-reload, que foi o único jeito
    // testado aqui já que não dá pra reiniciar o sistema de verdade nesta
    // sessão). Mesmo espírito do "activeWindowProc" acima: reagir a um
    // sinal explícito em vez de confiar cegamente num binding implícito.
    property int refreshTick: 0

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.refreshTick++ }
    }

    Connections {
        target: DockConfig
        function onPinnedIdsChanged() { root.refreshTick++ }
    }

    // Lê "applications.values" direto (mesmo padrão de DockPage.qml/
    // LauncherWindow.qml) em vez de "DesktopEntries.byId(id)" - byId() é
    // uma função invocável que NÃO cria dependência reativa com o escaneio
    // dos .desktop files (que roda async, ainda incompleto quando o
    // quickshell sobe cedo no autostart do Hyprland). Usando byId() aqui,
    // essa lista ficava presa vazia pro resto da sessão sempre que o
    // primeiro cálculo rodava antes do escaneio terminar - era o "apps não
    // carregam ao iniciar o sistema" reportado.
    readonly property var pinnedEntries: {
        root.refreshTick // dependência explícita, ver comentário acima
        const all = DesktopEntries.applications.values
        return DockConfig.pinnedIds
            .map(id => all.find(a => a.id === id))
            .filter(e => e !== undefined)
    }

    // Lista final: fixados primeiro (cada um já com o toplevel resolvido,
    // se estiver rodando), depois qualquer app RODANDO que não bateu com
    // nenhum fixado - pra não aparecer duas vezes o mesmo app.
    readonly property var items: {
        const pinned = root.pinnedEntries.map(entry => ({ entry: entry, toplevel: root.findToplevel(entry) }))
        const pinnedToplevels = pinned.map(p => p.toplevel).filter(t => t !== null)
        const extra = root.toplevels
            .filter(t => !pinnedToplevels.includes(t))
            .map(t => ({ entry: null, toplevel: t }))
        return pinned.concat(extra)
    }

    // Faixa sensível colada na borda inferior, sempre presente (mesmo com
    // o cartão escondido) - a superfície da janela inteira já ocupa a
    // borda de baixo o tempo todo (implicitHeight fixo), só o CARTÃO que
    // desliza pra fora de vista, então essa faixa continua alcançável.
    Item {
        id: hoverZone
        readonly property bool hovered: hoverHandler.hovered

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 12

        HoverHandler { id: hoverHandler }
    }

    Shadow { target: bg }

    Rectangle {
        id: bg

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // Escondido: desliza pra baixo da própria borda da janela (margin
        // negativo do tamanho do cartão) - fica fora da superfície, não só
        // invisível, então não rouba clique de ninguém enquanto escondido.
        anchors.bottomMargin: root.revealed ? root.restMargin : -root.cardHeight
        implicitWidth: Math.max(row.implicitWidth + Styles.spacing * 2, 64)
        implicitHeight: root.cardHeight
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }

        HoverHandler { id: cardHover }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Styles.spacing

            Repeater {
                model: root.items

                DockButton {
                    id: dockButton

                    required property var modelData

                    entry: dockButton.modelData.entry
                    toplevel: dockButton.modelData.toplevel

                    onActivated: {
                        if (dockButton.toplevel) dockButton.toplevel.activate()
                        else if (dockButton.entry) dockButton.entry.execute()
                    }
                }
            }

            Text {
                visible: root.items.length === 0
                text: "Nenhum app fixado"
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: Styles.border
            }

            // Fixa/desfixa o dock em si (DockConfig.pinned) - não confundir
            // com o Switch de cada app fixado (esse aqui é "manter o
            // painel do dock sempre visível", ver comentário grande no
            // topo do arquivo).
            IconButton {
                icon: "pin-angle"
                size: 32
                active: DockConfig.pinned
                onClicked: DockConfig.setDockPinned(!DockConfig.pinned)
            }
        }
    }
}
