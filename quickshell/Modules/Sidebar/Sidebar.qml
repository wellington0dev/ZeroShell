import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Capture

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

    Shadow { target: bg }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Colors.background
        border.color: Colors.border
        radius: Colors.radiusMedium
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacing
            spacing: Colors.spacing

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

            // Abre o chat da Helena (Modules/Helena).
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showHelena
                icon: "chat"
                active: Visibility.helenaOpen
                onClicked: Visibility.helenaOpen = !Visibility.helenaOpen
            }

            // Abre o chat de voz da Helena (Modules/Helena/VoiceWidget.qml).
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                visible: SidebarConfig.showVoice
                icon: "mic"
                active: Visibility.voiceOpen
                onClicked: Visibility.voiceOpen = !Visibility.voiceOpen
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
                Layout.bottomMargin: Colors.spacing
                visible: SidebarConfig.showPower
                icon: "shutdown"
                active: Visibility.powerMenuOpen
                onClicked: Visibility.powerMenuOpen = !Visibility.powerMenuOpen
            }
        }
    }
}
