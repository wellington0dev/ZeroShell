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
import qs.Modules.Power
import qs.Modules.Capture
import qs.Modules.Dashboard
import qs.Modules.Lock
import qs.Modules.Volume
import qs.Modules.Plugins
import qs.Modules.Dock
import qs.State

ShellRoot {
    Sidebar {}
    SettingsWindow {}
    NotificationPopups {}
    LauncherWindow {}
    PowerMenu {}
    DashboardTrigger {}
    DashboardWindow {}
    LockScreen {}
    VolumeTrigger {}
    VolumePanel {}
    DockWindow {}

    // Componente "main" de cada plugin instalado e ligado (ver
    // Modules/Plugins/PluginService.qml) - mesmo tratamento "sempre
    // instanciado" que os módulos embutidos acima recebem, pra IPC/timers/
    // lógica de fundo do plugin funcionarem. Plugin sem "main" no manifesto
    // (só sidebar e/ou settingsPage) não ganha um Loader aqui - não tem
    // nada pra manter vivo.
    //
    // O "Item" em volta do Repeater é necessário - testado ao vivo que um
    // Repeater direto dentro de ShellRoot não cria NENHUM delegate (nem
    // erro, nem log, simplesmente nada), porque ShellRoot não é um
    // Item/Layout de verdade pro Repeater inserir os filhos gerados. Um
    // Loader avulso (sem Repeater) funciona direto sob ShellRoot (ver
    // CaptureMenu/CapturePicker abaixo) - só o Repeater precisa desse
    // Item por baixo.
    Item {
        Repeater {
            model: PluginService.plugins

            Loader {
                id: pluginMainLoader

                required property var modelData

                active: modelData.enabled && !!modelData.main
                source: active ? ("file://" + modelData.dir + "/" + modelData.main) : ""

                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.log("Plugin \"" + modelData.id + "\": erro ao carregar \"" + modelData.main + "\" - " + modelData.dir)
                    }
                }
            }
        }
    }

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
