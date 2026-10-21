import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Dashboard
// Import do PRÓPRIO módulo (esta sidebar mora em qs.Modules.Sidebar): é o que
// dá acesso ao "ProfilePicture", que é passado pra TopSection pelo
// "profileComponent" - lá dentro (módulo filho RumdaBarSections) um import do
// módulo pai criaria ciclo, porque o pai é este arquivo.
import qs.Modules.Sidebar
import qs.Modules.Capture
import qs.Modules.Sidebar.RumdaBarSections
import qs.Modules.Sidebar.RumdaBarModules
import qs.Modules.Sidebar.RumdaBarModules
import qs.Modules.Sidebar.RumdaConfig

// A barra vertical fixa na borda esquerda da tela - o "tronco" do shell.
// Baseada na barra horizontal do Rumda (pistachio), adaptada para sidebar vertical.
PanelWindow {
    id: root

    // A sidebar sempre flutua do mesmo jeito, ligada ou não a borda da tela
    // (Modules/ScreenBorder) - ela já não precisa mais se fundir com a borda
    // pra ficar com cara de "moldura contínua": quem faz esse papel agora é
    // o próprio wallpaper (Modules/Wallpaper/WallpaperWindow.qml), que já
    // nasce com cantos arredondados encostando exatamente onde a borda
    // termina. Chegou a existir aqui uma fusão de verdade (raio achatado +
    // ConcaveFillet pra uma curva côncava na costura) - removida porque
    // virou redundante com o wallpaper já resolvendo o "arredondado" sozinho.

    // Largura visual de sempre (56) + uma folga interna (shadowPad) só pra
    // sombra ter onde vazar - "bg" abaixo fica menor que a PanelWindow por
    // "shadowPad" de cada lado, e a folga é tirada das próprias margens
    // (nada de aumentar o footprint total: "outerGap - shadowPad" em cada
    // lado dá exatamente "outerGap" de posição final pra "bg" - ver
    // Shadow.qml pro porquê da folga ser necessária: sem ela a sombra é
    // cortada nas bordas da própria superfície Wayland, que sem folga
    // coincidem exatamente com "bg").
    // Espessura da barra: a largura (vertical) ou a altura (horizontal).
    readonly property int shellWidth: 46
    readonly property int shellHeight: 48

    readonly property int outerGapV: 30
    readonly property int outerGapH: 10
    readonly property int shadowPad: 10

    // ---- Posição (State/SidebarConfig.qml -> "position") ----
    // Uma barra só por vez: "left"/"right" na vertical, "top"/"bottom" na
    // horizontal. Todas as âncoras, margens e tamanhos abaixo saem daqui -
    // o conteúdo é o mesmo, só muda a orientação (ver o layout no "bg").
    readonly property bool horizontal: SidebarConfig.horizontal
    readonly property bool atRight: SidebarConfig.atRight
    readonly property bool atBottom: SidebarConfig.position === "bottom"

    // Na horizontal a barra ocupa a largura inteira da tela (ancoras dos dois
    // lados); na vertical, só a espessura dela.
    implicitWidth: horizontal ? Screen.width : shellWidth + shadowPad * 2
    implicitHeight: horizontal ? shellHeight + shadowPad * 2 : 0
    // Espaço reservado pro compositor: a espessura da barra, na orientação
    // dela. É o que impede uma janela de cobrir a barra.
    exclusiveZone: horizontal ? shellHeight : shellWidth
    color: "transparent"

    // Margens: a folga de "shadowPad" (transparente) sai de um dos lados, e
    // sobra "outerGap" de distância real entre a borda da tela e a "bg".
    margins {
        top: horizontal ? (atBottom ? 0 : outerGapH - shadowPad) : outerGapV - shadowPad
        bottom: horizontal ? (atBottom ? outerGapH - shadowPad : 0) : outerGapV - shadowPad
        left: horizontal ? outerGapV - shadowPad : (atRight ? 0 : outerGapH - shadowPad)
        right: horizontal ? outerGapV - shadowPad : (atRight ? outerGapH - shadowPad : 0)
    }

    anchors {
        top: horizontal ? !atBottom : true
        bottom: horizontal ? atBottom : true
        left: horizontal ? true : !atRight
        right: horizontal ? true : atRight
    }

    // A folga acima (shadowPad) é transparente e não tem clique nenhum -
    // sem isto ela roubaria hover/clique de quem estiver do lado direito da
    // sidebar (layer-shell não fica "clicável só onde tem conteúdo" sozinho,
    // mesmo problema documentado em Dock/DockWindow.qml).
    mask: Region { item: bg }

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
        anchors.margins: shadowPad
        implicitWidth: root.horizontal ? parent.width : shellWidth
        implicitHeight: root.horizontal ? shellHeight : parent.height
        width: implicitWidth
        height: implicitHeight
        color: Styles.background
        border.color: Styles.border
        radius: Styles.radiusShell
        border.width: 1

        // ---- Conteúdo: os mesmos módulos, em coluna ou em linha ----
        //
        // Vertical (esquerda/direita): TopSection em cima, workspaces no
        // centro, BottomSection embaixo, com 2 espaçadores elásticos.
        //
        // Horizontal (topo/rodapé): as mesmas três seções numa linha, com os
        // elásticos abrindo espaço - "top" vira esquerda, "bottom" vira
        // direita, o "center" continua no meio. Os módulos são os compactos
        // do Rumda (RumdaBarModules), que são feitos pra linha.
        Loader {
            anchors.fill: parent
            anchors.margins: Styles.spacing
            sourceComponent: root.horizontal ? horizontalContent : verticalContent
        }

        Component {
            id: verticalContent

            ColumnLayout {
                spacing: Styles.spacing

                // TopSection: foto de perfil + Clock + Volume + CPU/RAM. O
                // "profileComponent" é montado aqui porque só este arquivo vê
                // os dois módulos (o pai "qs.Modules.Sidebar" e o filho
                // "RumdaBarSections") sem ciclo de import.
                TopSection {
                    profileComponent: Component { ProfilePicture {} }
                }

                Item { Layout.fillHeight: true }   // elástico

                CenterSection {}                  // Workspaces

                Item { Layout.fillHeight: true }   // elástico

                // BottomSection: tema + clima + wi-fi + power.
                // O "wifiComponent" é o WifiButton.qml do shell, montado aqui
                // porque só este arquivo vê o módulo pai ("qs.Modules.Sidebar")
                // e o filho ("RumdaBarSections") sem ciclo de import.
                BottomSection {
                    wifiComponent: Component { WifiButton {} }
                }
            }
        }

        Component {
            id: horizontalContent

            // Peças deitadas, com altura de barra (48px) em vez dos tiles
            // altos do Rumda - ver o comentário do arquivo.
            BarHorizontal {
                // Mesmo WifiButton da vertical, no tamanho dos tiles da barra.
                wifiComponent: Component { WifiButton { buttonSize: Styles.control } }
            }
        }
    }
}
