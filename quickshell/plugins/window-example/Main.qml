import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

// ============================================================================
// EXEMPLO 2 DE PLUGIN: uma janela de verdade, com tema.
// ============================================================================
//
// O plugin "hello-world" (na pasta ao lado) mostra os 4 pontos de integração
// do manifesto sem nenhuma interface visual própria. Este aqui foca só num
// deles - "main" - e mostra como abrir uma JANELA (PanelWindow) que se
// comporta e se PARECE com qualquer módulo nativo do shell (menu de
// energia, dashboard, etc.), incluindo reagir ao tema em tempo real.
//
// Como o Quickshell carrega isto: o PluginService (Modules/Plugins/
// PluginService.qml) descobre este plugin.json, vê o campo "main": "Main.qml"
// e o shell.qml principal instancia este arquivo com um Loader permanente -
// exatamente como faz com Sidebar{}/PowerMenu{}/DashboardWindow{} nativos.
// Ou seja: este componente fica vivo o tempo todo (mesmo escondido), então é
// aqui que mora o estado (a variável "open" abaixo) e o IpcHandler.
//
// Por que "root.open" é uma property LOCAL, e não algo em State/Visibility.qml
// (o singleton que o shell nativo usa pra isso)? Porque plugins não devem
// mexer em arquivos do core do shell - Visibility.qml é do shell, não do
// plugin. Cada plugin cuida do próprio estado de visibilidade sozinho, do
// jeito abaixo (property bool + IpcHandler). Isso também é por que o botão
// da sidebar (SidebarButton.qml, arquivo irmão deste) não liga "root.open"
// diretamente - ele é um Loader CARREGADO SEPARADO deste arquivo (o
// PluginService instancia "main" e "sidebar.component" cada um com o seu
// próprio Loader), então não existe uma referência QML direta entre os
// dois. A ponte entre eles é IPC: o botão roda "qs ipc call windowexample
// toggle", que cai bem aqui.
PanelWindow {
    id: root

    // Estado de aberto/fechado deste plugin - só existe enquanto o shell
    // roda (não é salvo em disco; se quiser persistir, o padrão do resto
    // do shell é um FileView + JsonAdapter, ver PluginService.qml pra um
    // exemplo comentado).
    property bool open: false

    IpcHandler {
        // Nome do alvo IPC - escolha algo único (não pode colidir com os
        // alvos nativos: sidebar, settings, powermenu, dashboard, etc, nem
        // com o de outro plugin instalado). Testa com:
        //   qs ipc call windowexample toggle
        target: "windowexample"

        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    // ---- A janela em si ----
    //
    // Mesmo truque que PowerMenu.qml/DashboardWindow.qml usam: a
    // PanelWindow cobre a tela inteira (transparente, sem decoração), e o
    // conteúdo de verdade é um Rectangle menor lá dentro, posicionado do
    // jeito que fizer sentido. Isso é o que permite clicar FORA do
    // cartão pra fechar (ver MouseArea logo abaixo) sem precisar de um
    // segundo componente.
    visible: root.open
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 360
        height: 220

        // ---- Integração com o tema (o ponto principal deste exemplo) ----
        //
        // "qs.Theme" é importado no topo do arquivo igual qualquer módulo
        // nativo faria - mesmo sendo este um arquivo carregado de fora da
        // árvore do shell (plugins/), o import funciona porque a resolução
        // é pelo caminho configurado no engine QML, não pela pasta de onde
        // o arquivo veio (ver comentário parecido em SidebarButton.qml).
        //
        // "Styles" é um singleton que lê State/colors.json por baixo dos
        // panos (Theme/Styles.qml, se quiser ver como). Isso quer dizer que
        // as cores abaixo (radius, background, border, foreground, accent)
        // ATUALIZAM SOZINHAS quando o usuário troca de wallpaper (matugen
        // gera cores novas) ou mexe em Configurações > Aparência >
        // Personalizar - sem o plugin precisar fazer nada além de usar
        // "Styles.algumaCoisa" normalmente, do jeito abaixo. Teste ao vivo:
        // abra esta janela, troque a cor de destaque nas Configurações, e
        // veja a borda/botão mudarem sozinhos.
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing * 2
            spacing: Styles.spacing * 1.5

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Janela de Exemplo"
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeLarge
                    font.family: Styles.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "close"
                    size: 24
                    onClicked: root.open = false
                }
            }

            Text {
                text: "Isto é uma PanelWindow normal, aberta pelo \"main\" de um plugin. As cores aqui vêm de Styles (qs.Theme) - o mesmo tema usado pelo resto do shell."
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Styles.spacing

                Text {
                    text: "Cliques: " + counter.count
                    color: Styles.accent
                    font.pixelSize: Styles.fontSizeNormal
                    font.family: Styles.fontFamily
                    Layout.fillWidth: true
                }

                Button {
                    text: "Clicar"
                    onClicked: counter.count++
                }
            }
        }

        // Estado de exemplo só pra mostrar que a janela é interativa de
        // verdade (não é uma imagem estática) - nada de especial aqui, é
        // só um QtObject com uma property int comum.
        QtObject {
            id: counter
            property int count: 0
        }
    }

    // Quer animação de abrir/fechar (slide, fade) igual PowerMenu/Dashboard
    // nativos? Dá pra reusar Widgets/PanelAnim.qml e Widgets/Shadow.qml do
    // shell do mesmo jeito que Styles foi usado acima (import qs.Widgets já
    // tá no topo) - veja Modules/Power/PowerMenu.qml como referência
    // completa. Deixado de fora aqui de propósito, pra este exemplo focar só
    // em "janela + tema" sem inflar o arquivo.
}
