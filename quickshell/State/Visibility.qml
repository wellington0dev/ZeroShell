pragma Singleton

import Quickshell

// Estado compartilhado de "o que está aberto" no shell. Cada painel flutuante
// (Settings, Launcher, Helena, menu de energia) só tem um jeito de
// abrir/fechar: um botão na sidebar troca o bool aqui, e a janela do módulo
// correspondente faz "visible: Visibility.xxxOpen". Como é um singleton, tanto
// o botão (em Modules/Sidebar) quanto a janela (em outro módulo qualquer)
// enxergam o mesmo valor sem precisar se conhecer diretamente.
//
// O Player não tem uma entrada aqui - ele mora numa aba do Dashboard agora
// (Modules/Dashboard/PlayerTab.qml), que abre/fecha por hover
// (DashboardState.qml), não por clique.
Singleton {
    property bool settingsOpen: false
    property bool launcherOpen: false
    property bool helenaOpen: false
    property bool powerMenuOpen: false
    property bool captureMenuOpen: false
    property bool voiceOpen: false
}
