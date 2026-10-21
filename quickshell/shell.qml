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
import qs.Modules.Dashboard.RumdaDashboard
import qs.Modules.Launcher
import qs.Modules.Power
import qs.Modules.Capture
import qs.Modules.Dashboard
import qs.Modules.Lock
import qs.Modules.Volume
import qs.Modules.Dock
import qs.State

ShellRoot {
    // Só a SidebarNew está ativa. A "Sidebar" antiga (Modules/Sidebar/
    // Sidebar.qml) continua no código, funcionando e sem warning, mas não é
    // instanciada: as duas declararem "exclusiveZone: 56" fazia o Hyprland
    // reservar 112px e as duas barras apareciam lado a lado.
    // Sidebar {}

    // Barra vertical do shell, no estilo Rumda (TopSection/CenterSection/
    // BottomSection). Usa as cores do tema via Styles + RumdaConfig/Colors.
    SidebarNew {}
    SettingsWindow {}
    // NotificationPopups {}   // trocado pelos toasts do Rumda
    // (Modules/Dashboard/RumdaDashboard/Notifications.qml), que usam o MESMO
    // NotificationService - um servidor de notificações só. Este continua no
    // código caso queira voltar atrás.
    RumdaNotifications {}
    LauncherWindow {}
    PowerMenu {}
    // Dashboard: o gatilho de hover (DashboardTrigger) saiu na Fase 3 - a
    // janela virou WlrLayershell com foco exclusivo de teclado, e uma faixa
    // sensível de 10px no topo da tela passaria a competir com o teclado e com
    // o clique-fora do próprio painel. A abertura passa a ser pelo atalho
    // (Configurações > Atalhos -> Super+TAB) ou por IPC.
    // DashboardWindow {}

    // Card do Dashboard no estilo Rumda (Modules/Dashboard/RumdaDashboard/),
    // usando o mesmo DashboardState/IPC do DashboardWindow.
    Dashboard {}
    LockScreen {}
    VolumeTrigger {}
    VolumePanel {}
    //DockWindow {}

    // CaptureMenu e CapturePicker são os únicos painéis que, ao fechar,
    // precisam ser DESTRUÍDOS de verdade (não só escondidos) - veja os
    // comentários em CaptureMenu.qml/CapturePicker.qml pra entender por quê
    // (disputa de superfície em tela cheia com o slurp/grim).
    Loader {
        active: Visibility.captureMenuOpen
        sourceComponent: CaptureMenu {}
    }

    Loader {
        active: CaptureService.pickerOpen
        sourceComponent: CapturePicker {}
    }
}
