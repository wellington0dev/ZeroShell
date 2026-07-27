// Ponto de entrada do shell - é o arquivo que o comando "qs" carrega
// (~/.config/quickshell/shell.qml). Só importa cada módulo e instancia um de
// cada: cada um é uma janela (PanelWindow ou FloatingWindow) independente que
// decide sozinha quando aparecer (quase todas via State/Visibility.qml).
//
// A ordem aqui não importa pra funcionamento - cada módulo é autônomo -, mas
// segue a ordem em que foram criados neste projeto.
import QtQuick
import Quickshell
import qs.Modules.Sidebar
import qs.Modules.Settings
import qs.Modules.Notifications
import qs.Modules.Launcher
import qs.Modules.Helena
import qs.Modules.Power
import qs.Modules.Capture
import qs.Modules.Dashboard
import qs.State

ShellRoot {
    Sidebar {}
    SettingsWindow {}
    NotificationPopups {}
    LauncherWindow {}
    HelenaWindow {}
    VoiceWidget {}
    PowerMenu {}
    DashboardTrigger {}
    DashboardWindow {}

    // CaptureMenu é o único painel que, ao fechar, precisa ser DESTRUÍDO de
    // verdade (não só escondido) - veja o comentário em CaptureMenu.qml pra
    // entender por quê (disputa de superfície em tela cheia com o slurp).
    Loader {
        active: Visibility.captureMenuOpen
        sourceComponent: CaptureMenu {}
    }
}
