import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Capture
import qs.Modules.Plugins

// A barra vertical fixa na borda esquerda da tela - o "tronco" do shell.
// É uma PanelWindow (janela do tipo layer-shell, pensada pra barras/painéis,
// não uma janela normal de aplicativo) ancorada nas bordas top+bottom+left,
// o que faz o Hyprland reservar aquele espaço (exclusiveZone) pra ela nunca
// ficar coberta por outras janelas.
//
// Não tem lógica própria além de organizar os módulos visualmente em 3
// sub-colunas (topo/centro/rodapé), separadas por dois espaçadores
// elásticos ("Item { Layout.fillHeight: true }") - cada item escolhe o seu
// grupo em Configurações > aba Sidebar (SidebarConfig.getAlign/setAlign),
// dentro do mesmo grupo a ordem segue "defaultOrder" (builtins) + a ordem
// de descoberta dos plugins (PluginService.plugins). Cada item continua
// sendo um componente de outro arquivo (muitos deles simples botões que só
// viram true/false uma propriedade em State/Visibility.qml pra abrir/
// fechar o painel flutuante correspondente) - só a ORGANIZAÇÃO em 3 grupos
// é data-driven agora (ver "allItems"/"itemsForAlign" abaixo), pra um
// mesmo item poder trocar de grupo sem precisar mover código.
PanelWindow {
    id: root

    implicitWidth: 56
    exclusiveZone: implicitWidth
    color: "transparent"
    margins{
        top: 30
        left: 10
        bottom: 30
    }

    anchors {
        top: true
        bottom: true
        left: true
    }

    // Toggle "Manter acordado" (Dashboard > aba Ajustes) - impede o sistema
    // de suspender/apagar a tela (DPMS) enquanto ligado. Precisa de uma
    // janela mapeada de verdade pra se "prender" (protocolo
    // zwp_idle_inhibit_manager_v1 inibe enquanto ESSA superfície existir) -
    // a Sidebar serve porque vive o tempo todo que o shell existe. Só isso
    // não desliga o auto-lock da nossa própria lockscreen (timer em
    // software, não pede nada pro sistema) - LockScreen.qml também confere
    // "QuickSettings.keepAwake" separadamente pra isso.
    IdleInhibitor {
        window: root
        enabled: QuickSettings.keepAwake
    }

    Shadow { target: bg }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Styles.background
        border.color: Styles.border
        radius: Styles.radiusShell
        border.width: 1

        // Componentes dos itens fixos, um Component por "id" curto (mesmas
        // chaves de SidebarConfig.defaultAlign) - guardam as bindings
        // originais de cada item (ícone, "active", "onClicked"),
        // só não têm mais "Layout.alignment"/"visible" aqui porque quem
        // instancia isso é o Loader dos Repeaters abaixo, que já cuida
        // disso. Indexados via "builtinComponents" mais abaixo.
        Component { id: profileComp; ProfilePicture {} }

        Component {
            id: launcherComp
            IconButton {
                icon: "search"
                active: Visibility.launcherOpen
                onClicked: Visibility.launcherOpen = !Visibility.launcherOpen
            }
        }

        Component { id: workspacesComp; Workspaces {} }

        // Ícones de apps rodando em segundo plano (Spotify/Discord/Steam).
        Component { id: appTrayComp; AppTray {} }

        Component { id: clockComp; Clock {} }

        Component { id: batteryComp; Battery {} }

        // Estado do Wi-Fi + atalho pra Configurações > aba Wi-Fi.
        Component { id: wifiComp; WifiButton {} }

        // Estado do Bluetooth + atalho pra Configurações > aba Bluetooth.
        Component { id: bluetoothComp; BluetoothButton {} }

        // Captura/gravação de tela (Modules/Capture).
        Component { id: captureComp; CaptureIndicator {} }

        // Abre a janela de Configurações (Modules/Settings).
        Component {
            id: settingsComp
            IconButton {
                icon: "gear"
                active: Visibility.settingsOpen
                onClicked: Visibility.settingsOpen = !Visibility.settingsOpen
            }
        }

        // Abre o menu de energia (Modules/Power).
        Component {
            id: powerComp
            IconButton {
                icon: "shutdown"
                active: Visibility.powerMenuOpen
                onClicked: Visibility.powerMenuOpen = !Visibility.powerMenuOpen
            }
        }

        readonly property var builtinComponents: ({
            profile: profileComp,
            launcher: launcherComp,
            workspaces: workspacesComp,
            appTray: appTrayComp,
            clock: clockComp,
            battery: batteryComp,
            wifi: wifiComp,
            bluetooth: bluetoothComp,
            capture: captureComp,
            settings: settingsComp,
            power: powerComp
        })

        // Lista única de itens visíveis agora (fixos + plugins), cada um já
        // com o grupo ("align") e a posição dentro do grupo ("order",
        // menor primeiro) escolhidos em Configurações > aba Sidebar.
        // "itemsForAlign" abaixo filtra E ordena essa lista pra cada uma
        // das 3 sub-colunas.
        //
        // O índice de cada item no array ORIGINAL (antes de filtrar por
        // visibilidade) vira o "fallback" passado pra
        // SidebarConfig.getOrder - preserva a ordem de sempre (fixos, na
        // ordem declarada abaixo; plugins depois, na ordem em que o
        // PluginService os descobriu) até o usuário mexer nas setas ▲▼.
        //
        // Ícone de plugin: "enabled" sozinho NÃO basta pra aparecer aqui -
        // precisa também estar marcado na aba Sidebar
        // (SidebarConfig.isPluginIconVisible, opt-in e desligado por
        // padrão). Ligar um plugin não deve mudar a sidebar sozinho.
        readonly property var allItems: {
            const builtins = [
                { id: "profile", visible: SidebarConfig.showProfile },
                { id: "launcher", visible: SidebarConfig.showLauncher },
                { id: "workspaces", visible: SidebarConfig.showWorkspaces },
                { id: "appTray", visible: SidebarConfig.showAppTray },
                { id: "clock", visible: SidebarConfig.showClock },
                { id: "battery", visible: SidebarConfig.showBattery },
                { id: "wifi", visible: SidebarConfig.showWifi },
                { id: "bluetooth", visible: SidebarConfig.showBluetooth },
                { id: "capture", visible: SidebarConfig.showCapture },
                { id: "settings", visible: SidebarConfig.showSettings },
                { id: "power", visible: SidebarConfig.showPower }
            ]
                .map((i, idx) => ({ id: i.id, visible: i.visible, fallbackOrder: idx }))
                .filter(i => i.visible)
                .map(i => ({
                    id: i.id,
                    isPlugin: false,
                    align: SidebarConfig.getAlign(i.id),
                    order: SidebarConfig.getOrder(i.id, i.fallbackOrder)
                }))

            const plugins = PluginService.plugins
                .map((p, idx) => ({ p: p, fallbackOrder: 100 + idx }))
                .filter(o => o.p.enabled && o.p.sidebar && o.p.sidebar.component && SidebarConfig.isPluginIconVisible(o.p.id))
                .map(o => ({
                    id: o.p.id,
                    isPlugin: true,
                    dir: o.p.dir,
                    component: o.p.sidebar.component,
                    align: SidebarConfig.getAlign(o.p.id),
                    order: SidebarConfig.getOrder(o.p.id, o.fallbackOrder)
                }))

            return builtins.concat(plugins)
        }

        function itemsForAlign(align) {
            return bg.allItems.filter(i => i.align === align).sort((a, b) => a.order - b.order)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing
            spacing: Styles.spacing

            Repeater {
                model: bg.itemsForAlign("top")
                delegate: Loader {
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    sourceComponent: modelData.isPlugin ? null : bg.builtinComponents[modelData.id]
                    source: modelData.isPlugin ? ("file://" + modelData.dir + "/" + modelData.component) : ""
                }
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: bg.itemsForAlign("center")
                delegate: Loader {
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    sourceComponent: modelData.isPlugin ? null : bg.builtinComponents[modelData.id]
                    source: modelData.isPlugin ? ("file://" + modelData.dir + "/" + modelData.component) : ""
                }
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: bg.itemsForAlign("bottom")
                delegate: Loader {
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
                    sourceComponent: modelData.isPlugin ? null : bg.builtinComponents[modelData.id]
                    source: modelData.isPlugin ? ("file://" + modelData.dir + "/" + modelData.component) : ""
                }
            }
        }
    }
}
