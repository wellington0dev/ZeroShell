import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Theme
import qs.Widgets
import qs.Modules.Sidebar
// Sem import de qs.Modules.Power nem de qs.Modules.Lock DE PROPÓSITO: nada
// daqui usa PowerButton ou LockScreen. As duas ações que tocam esses módulos
// (travar, suspender) vão pelo IPC que eles já expõem ("lockscreen lock") e
// pelo mesmo comando de sempre, então não há nada a importar. Sobrando o
// import, o probe de validação carregaria dois módulos a mais sem necessidade.

// ============================================================================
// Perfil + energia dentro do Dashboard (Fase 3).
// ============================================================================
//
// O Rumda tem um módulo gigante para isto (dark/widgets/ProfileAndPower.qml,
// 609 linhas) que AMPLIA o que já existe: foto de perfil grande em círculo com
// botões flutuando ao redor (suspender/reiniciar/desligar/sair/travar), uma
// "PowerProfile" e um leitor de bateria.
//
// Aqui não foi portado. Motivos, na ordem de peso:
//
//  1. Duplicaria serviço e janela. A Powershell do ZeroShell JÁ tem esse
//     conjunto exato de ações (Modules/Power/PowerMenu.qml): travar, sair,
//     suspender, reiniciar e desligar, cada um com o mesmo comando e a mesma
//     confirmação de dois passos. E a foto de perfil JÁ existe
//     (Modules/Sidebar/ProfilePicture.qml, com o mesmo tratamento de ~/.face e
//     recarga). Um ProfileAndPower de 609 linhas aqui seria uma segunda
//     interface de energia e uma segunda foto de perfil - o oposto de "não
//     implemente uma segunda versão do que já é atendido".
//
//  2. Os comandos do Rumda são hardcoded para o Fedora e não batem com o que
//     o shell já usa: ele chama "hyprshutdown"/"systemctl suspend"/"systemctl
//     reboot"/"systemctl poweroff" e a lockscreen PRÓPRIA (via IPC "lockscreen
//     lock"), não "hyprlock". Copiar os comandos do Rumda trocaria o
//     comportamento correto por um que nem está instalado.
//
// O QUE FICOU: um resumo de perfil + bateria/UPower dentro do Dashboard, e um
// botão que ABRE o menu de energia que já existia. O painel deixa de ser um
// lugar onde se navega entre duas janelas para as ações destrutivas, mas não
// duplica nada: as ações continuam num lugar só (a PowerMenu), que é a razão de
// ela existir separada - ações de desligar não pertencem a um painel que o
// usuário abre para olhar o sistema.
Rectangle {
    id: root

    // Ver comentário do componente. Só para teste; o Dashboard usa false.
    // Quando false, nada aqui executa comando nenhum.
    property bool readOnly: false

    Layout.fillWidth: true
    Layout.preferredHeight: 108
    radius: Styles.radiusShell
    color: Styles.surface
    border.color: Styles.border
    border.width: 1

    // Bateria via UPower - mesmo acesso do SystemTab (UPower.displayDevice e
    // o enum UPowerDeviceState), ou seja, o MESMO objeto e o MESMO serviço que
    // a aba Sistema já consome. Nada de serviço novo: só mais um leitor.
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool batteryReady: battery && battery.ready && battery.isLaptopBattery
    // "percentage" é uma FRAÇÃO (0..1), e não uma porcentagem - é o mesmo
    // cálculo do SystemTab.qml:24. Ler "charge" (que nem existe no
    // UPowerDevice) dava 0% na tela.
    readonly property int batteryPercent: batteryReady ? Math.round(battery.percentage * 100) : -1

    // ---- Ações ----
    // Cada uma delega ao mecanismo que JÁ existe, em vez de executar o comando
    // por conta própria. "run" é o mesmo utilitário da PowerMenu, e a
    // lockscreen é chamada pelo IPC que o PowerMenu usa.
    function run(cmd) {
        if (root.readOnly) return
        proc.command = cmd
        proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-c", "true"]
        running: false
    }

    // Abre a PowerMenu (o menu de energia que já existia). Não é "abrir o
    // dashboard": é chamar outro painel. Como os dois são layer-shell com
    // teclado exclusivo, o painel do Dashboard precisa soltar o foco antes -
    // senão a PowerMenu, que é PanelWindow comum, abriria por baixo sem
    // conseguir o teclado. Fecha o Dashboard primeiro e a PowerMenu abre em
    // seguida pelo IPC dela.
    function openPowerMenu() {
        if (root.readOnly) return
        // Target conferido no IpcHandler da própria PowerMenu (Modules/Power/
        // PowerMenu.qml:24): "powermenu", não "power".
        closeProcess.command = ["bash", "-c", "qs ipc call dashboard close; sleep 0.12; qs ipc call powermenu toggle"]
        closeProcess.running = true
    }

    Process {
        id: closeProcess
        command: ["bash", "-c", "true"]
        running: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ProfilePicture { size: 40 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Sessão"
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeNormal
                    font.bold: true
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.batteryPercent >= 0
                        ? "Bateria " + root.batteryPercent + "%"
                        : "Sem bateria"
                    color: Styles.foregroundMuted
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            // Botões de ação rápida. "travar" e "suspender" são ações que não
            // destroem nada, então vão diretos (mesma política da PowerMenu:
            // needsConfirm só em reiniciar/desligar, que ficam na PowerMenu).
            // Suspender/travar vão pelo mesmo caminho de sempre - o IPC do
            // lockscreen e o systemctl da PowerMenu - e não por comando novo.
            IconButton {
                icon: "lock"
                size: 30
                enabled: !root.readOnly
                opacity: root.readOnly ? 0.4 : 1
                onClicked: root.run(["qs", "ipc", "call", "lockscreen", "lock"])
            }

            IconButton {
                icon: "suspend"
                size: 30
                enabled: !root.readOnly
                opacity: root.readOnly ? 0.4 : 1
                onClicked: root.run(["systemctl", "suspend"])
            }

            Item { Layout.fillWidth: true }

            // Entrada para o menu de energia completo (sair/reiniciar/desligar,
            // com confirmação). Texto em vez de ícone porque a ação pede um
            // rótulo legível - "desligar" e "reiniciar" são seriousos demais
            // para um ícone sem palavra.
            Rectangle {
                id: menuBtn
                Layout.preferredHeight: 30
                implicitWidth: menuLabel.implicitWidth + 20
                radius: Styles.radiusButton
                // "menuHover.hovered" pelo ID, nunca "menuBtn.hover.hovered": um
                // HoverHandler é um PointerHandler (não é Item), logo não vira
                // propriedade do pai e a forma "pai.hover" devolve undefined.
                color: menuHover.hovered && menuBtn.enabled ? Styles.surfaceAlt : "transparent"
                border.color: Styles.border
                border.width: 1
                enabled: !root.readOnly
                opacity: root.readOnly ? 0.4 : 1

                Behavior on color { ColorAnimation { duration: Motion.durationFast } }

                Text {
                    id: menuLabel
                    anchors.centerIn: parent
                    text: "Energia"
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                }

                HoverHandler { id: menuHover; enabled: menuBtn.enabled }
                TapHandler { enabled: menuBtn.enabled; onTapped: root.openPowerMenu() }
            }
        }
    }
}