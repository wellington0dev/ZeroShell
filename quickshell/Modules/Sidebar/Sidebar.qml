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
// Não tem lógica própria além de organizar os módulos visualmente numa
// coluna: cada item aqui é um componente de outro arquivo (muitos deles
// simples botões que só viram true/false uma propriedade em
// State/Visibility.qml pra abrir/fechar o painel flutuante correspondente).
// Os dois "Item { Layout.fillHeight: true }" são espaçadores elásticos que
// empurram os Workspaces pro centro vertical da barra.
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
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing
            spacing: Styles.spacing

            ProfilePicture {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showProfile
            }

            // Abre o launcher de aplicativos (Modules/Launcher).
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showLauncher
                icon: "search"
                active: Visibility.launcherOpen
                onClicked: Visibility.launcherOpen = !Visibility.launcherOpen
            }

            Item { Layout.fillHeight: true }

            Workspaces {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showWorkspaces
            }

            Item { Layout.fillHeight: true }

            // Ícones de apps rodando em segundo plano (Spotify/Discord/Steam).
            AppTray {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showAppTray
            }

            Clock {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showClock
            }

            Battery {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showBattery
            }

            // Captura/gravação de tela (Modules/Capture).
            CaptureIndicator {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showCapture
            }

            // Ícone próprio de cada plugin instalado, ligado, com
            // "sidebar.component" no manifesto (ver
            // Modules/Plugins/PluginService.qml) - o componente carregado é
            // responsabilidade do próprio plugin desenhar (tamanho/estilo
            // parecido com um IconButton comum, pra caber na coluna de
            // 56px da sidebar).
            //
            // "enabled" sozinho NÃO basta pra aparecer aqui - precisa
            // também estar marcado na aba "sidebar" das Configurações
            // (SidebarConfig.isPluginIconVisible, opt-in e desligado por
            // padrão - ver Modules/Settings/SidebarPage.qml). Ligar um
            // plugin não deve mudar a sidebar sozinho.
            Repeater {
                model: PluginService.plugins

                Loader {
                    id: pluginSidebarLoader

                    required property var modelData

                    Layout.alignment: Qt.AlignHCenter
                    active: modelData.enabled && !!(modelData.sidebar && modelData.sidebar.component) && SidebarConfig.isPluginIconVisible(modelData.id)
                    source: active ? ("file://" + modelData.dir + "/" + modelData.sidebar.component) : ""
                }
            }

            // Abre a janela de Configurações (Modules/Settings).
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showSettings
                icon: "gear"
                active: Visibility.settingsOpen
                onClicked: Visibility.settingsOpen = !Visibility.settingsOpen
            }

            // Abre o menu de energia (Modules/Power).
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Styles.spacing
                visible: SidebarConfig.showPower
                icon: "shutdown"
                active: Visibility.powerMenuOpen
                onClicked: Visibility.powerMenuOpen = !Visibility.powerMenuOpen
            }
        }
    }
}
