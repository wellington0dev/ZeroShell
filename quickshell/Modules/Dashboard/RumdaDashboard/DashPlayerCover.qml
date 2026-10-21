import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets   // ClippingRectangle
import Quickshell.Services.Mpris
import qs.Theme
import qs.Widgets
import qs.Modules.Player

// Capa do player no painel central do Dashboard.
//
// A capa vem do MPRIS de verdade: "Player.active.trackArtUrl" (o mesmo que o
// PlayerContent.qml do shell usa), ou seja, a arte que o Spotify/YouTube/
// qualquer player MPRIS mandar. Sem player, sem capa, ou capa ainda
// carregando, cai no ícone de nota musical - nunca fica um buraco vazio.
//
// Título e artista ficam SOBRE a base da capa (com um scrim em degradê),
// não numa faixa abaixo. Numa faixa separada eles comiam ~38px da altura do
// painel - e como o painel do meio tem ~260px para greet + capa + controles,
// a capa ficava espremida em 64px. Sobrepondo, a capa usa tudo que sobra.
Item {
    id: root

    // ==========================================================================
    //  <<< AJUSTE AQUI >>>  TAMANHO DA CAPA
    // ==========================================================================
    //  A capa é quadrada e ocupa só a si mesma (texto por cima). Não é um
    //  número solto: é o MENOR entre o desejado e o que a faixa do meio do
    //  painel realmente tem, então se o painel apertar a capa encolhe em vez
    //  de invadir os controles de play.
    //      96 -> discreta
    //      132 -> ocupa bem o painel (atual)
    //      180 -> quase a largura inteira do painel (~250px)
    // ==========================================================================
    readonly property int coverSize: Math.max(64, Math.min(132, parent.height))

    readonly property var player: Player.active

    width: coverSize
    height: coverSize

    ClippingRectangle {
        id: coverBox

        anchors.fill: parent
        // Sem "Rectangle + clip: true": um Rectangle comum recorta numa caixa
        // reta e ignora o radius, então a capa quadrada apareceria por baixo
        // do canto arredondado.
        radius: Styles.radiusMedium
        color: Styles.surfaceAlt

        border.width: 1
        border.color: Styles.border

        Image {
            id: art
            anchors.fill: parent
            // "asynchronous" porque a capa vem de um servidor MPRIS (pode ser
            // base64 grande ou URL http) e travar a thread aqui congelaria o
            // painel inteiro.
            source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready

            Behavior on opacity {
                NumberAnimation { duration: Motion.durationFast }
            }
        }

        // Fallback: sem player, sem capa, ou ainda baixando.
        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            icon: "music-note"
            size: Math.round(root.coverSize / 3)
            tint: Styles.foregroundMuted
        }

        // ---- Título e artista sobre a base da capa ----
        // O scrim é um degradê (não um retângulo sólido) porque a arte pode ser
        // clara ou escura: sem ele, o texto branco sumia em capa clara.
        Rectangle {
            id: scrim
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(root.coverSize * 0.5)
            opacity: (root.player && root.player.trackTitle) ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.88) }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Styles.spacing
            anchors.rightMargin: Styles.spacing
            anchors.bottomMargin: Math.round(Styles.spacing * 0.8)
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nada tocando"
                color: Styles.foreground
                font.family: Styles.fontFamily
                font.pixelSize: Styles.fontSizeSmall
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.player && root.player.trackArtist
                text: root.player ? root.player.trackArtist : ""
                color: Styles.foregroundMuted
                font.family: Styles.fontFamily
                font.pixelSize: Styles.fontSizeSmallest
                elide: Text.ElideRight
            }
        }
    }
}