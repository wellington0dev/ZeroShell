import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.Theme
import qs.Widgets

// Conteúdo visual do player MPRIS (capa com anel de progresso em volta,
// título/álbum/artista, controles) - sem janela própria, embutido na aba
// "Player" do Dashboard. Estilo inspirado no caelestia
// (github.com/caelestia-dots/shell, módulo dashboard/dash/Media.qml): o
// anel de progresso circunda a capa em vez de ficar como barra separada, e
// os controles de prev/play/next viram pílulas em vez de ícones soltos.
//
// Layout em linha - capa à esquerda, infos + controles à direita -, com
// bastante espaço (30px) entre a capa e o resto e margem lateral extra pra
// não ficar colado nas bordas do card.
RowLayout {
    id: root

    readonly property MprisPlayer player: Player.active

    // Most MPRIS players (browsers especially) only report position on
    // seek/pause/track-change, not continuously during playback - this ticks
    // a local estimate once a second while playing and resyncs to the real
    // value whenever the player actually reports one, instead of the seek
    // bar only moving when the player happens to notify us.
    property real displayPosition: 0

    // Duração cacheada localmente, igual ao displayPosition acima, e pelo
    // MESMO motivo: "player.length" não é confiável pra ler direto/reativo a
    // cada instante - visto ao vivo que, logo depois de um seek, ele lê um
    // valor errado por um instante (bateu EXATAMENTE com a posição do seek,
    // não com a duração real da faixa), fazendo o rótulo "total" e a barra
    // de progresso enlouquecerem por um momento (o "buga tudo" relatado).
    // "playerctl metadata" confirmou que o mpris:length de verdade nunca
    // mudou - só a leitura reativa de "player.length" aqui ficava errada.
    // Por isso só resincroniza em eventos estruturais (troca de faixa/
    // player), nunca em resposta a "positionChanged".
    property real trackLength: 0

    readonly property real progress: trackLength > 0 ? displayPosition / trackLength : 0

    function resyncTrack() {
        displayPosition = player ? player.position : 0
        trackLength = player ? player.length : 0
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const total = Math.floor(seconds)
        const m = Math.floor(total / 60)
        const s = total % 60
        return m + ":" + String(s).padStart(2, "0")
    }

    Component.onCompleted: resyncTrack()
    onPlayerChanged: resyncTrack()

    Connections {
        target: root.player
        // Só a posição resincroniza a cada notificação - "trackLength" fica
        // de fora de propósito (ver comentário acima).
        function onPositionChanged() { root.displayPosition = root.player ? root.player.position : 0 }
        function onTrackChanged() { root.resyncTrack() }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying
        onTriggered: {
            root.displayPosition = Math.min(root.displayPosition + 1, root.trackLength)
        }
    }

    Layout.leftMargin: 22
    Layout.rightMargin: 22
    spacing: 30

    // Capa com o anel de progresso da faixa em volta - à esquerda.
    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 132
        Layout.preferredHeight: 132

        Shape {
            id: ring

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Styles.surfaceAlt
                strokeWidth: 4
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    radiusX: ring.width / 2 - 2
                    radiusY: ring.height / 2 - 2
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    startAngle: -90
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Styles.accent
                strokeWidth: 4
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    radiusX: ring.width / 2 - 2
                    radiusY: ring.height / 2 - 2
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    startAngle: -90
                    sweepAngle: 360 * Math.max(0, Math.min(1, root.progress))

                    Behavior on sweepAngle {
                        NumberAnimation { duration: Motion.durationSlow; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // "ClippingRectangle" em vez de Rectangle+clip:true: um Rectangle
        // comum só recorta numa caixa reta (ignora o radius), então a capa
        // quadrada continuaria aparecendo por baixo do círculo.
        ClippingRectangle {
            anchors.centerIn: parent
            width: parent.width - 14
            height: width
            radius: width / 2
            color: Styles.surfaceAlt

            Image {
                id: cover
                anchors.fill: parent
                source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                icon: "music-note"
                size: 28
                tint: Styles.foregroundMuted
            }
        }
    }

    // Infos + controles - à direita, alinhados à esquerda (não mais
    // centralizados embaixo da capa).
    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Styles.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Player.players.length > 1

            Repeater {
                model: Player.players

                delegate: Rectangle {
                    id: tab

                    required property var modelData

                    width: 24
                    height: 24
                    radius: Styles.radiusSmall
                    color: Player.active === modelData
                        ? Qt.rgba(Styles.accent.r, Styles.accent.g, Styles.accent.b, 0.18)
                        : (tabHover.hovered ? Styles.surfaceAlt : "transparent")
                    border.color: Player.active === modelData ? Styles.accent : "transparent"
                    border.width: 1

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 14
                        source: Quickshell.iconPath(tab.modelData.desktopEntry, true)
                    }

                    HoverHandler { id: tabHover }
                    TapHandler { onTapped: Player.select(tab.modelData) }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nada tocando"
            color: Styles.foreground
            font.pixelSize: 14
            font.family: Styles.fontFamily
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.player && root.player.trackAlbum ? root.player.trackAlbum : ""
            color: Styles.foregroundMuted
            font.pixelSize: 10
            font.family: Styles.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text.length > 0
        }

        Text {
            text: root.player ? root.player.trackArtist : ""
            color: Styles.accentAlt
            font.pixelSize: 11
            font.family: Styles.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text.length > 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 2

            Slider {
                Layout.fillWidth: true
                value: root.progress
                // "moved" só atualiza o rótulo de tempo local (barato, pode
                // disparar a cada pixel arrastado) - a busca de verdade via
                // MPRIS (player.position = ...) só acontece em "released",
                // uma vez só, ao soltar o botão. Usar "moved" pra isso
                // mandava uma busca por posição a cada movimento do mouse -
                // visto ao vivo travando o vídeo (várias buscas em sequência
                // rápida enquanto arrastava).
                onMoved: (v) => root.displayPosition = v * root.trackLength
                onReleased: (v) => {
                    if (root.player && root.player.canSeek) {
                        root.player.position = v * root.trackLength
                        root.displayPosition = v * root.trackLength
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.displayPosition)
                    color: Styles.foregroundMuted
                    font.pixelSize: 9
                    font.family: Styles.fontFamily
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(root.trackLength)
                    color: Styles.foregroundMuted
                    font.pixelSize: 9
                    font.family: Styles.fontFamily
                }
            }
        }

        // Controles em formato de pílula - prev/next tonais (fundo suave) e
        // o play/pause em destaque, preenchido com a cor de acento.
        // Centralizados em relação à barra de progresso (mesma largura da
        // coluna, já que ambos são fillWidth).
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Styles.spacing

            IconButton {
                icon: "shuffle"
                size: 20
                visible: root.player && root.player.shuffleSupported
                active: root.player && root.player.shuffle
                onClicked: root.player.shuffle = !root.player.shuffle
            }

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Styles.surfaceAlt
                opacity: (root.player && root.player.canGoPrevious) ? 1 : 0.4

                Icon {
                    anchors.centerIn: parent
                    icon: "skip-previous"
                    size: 16
                    tint: Styles.foreground
                }

                TapHandler {
                    enabled: root.player && root.player.canGoPrevious
                    onTapped: root.player.previous()
                }
            }

            Rectangle {
                width: 60
                height: 40
                radius: 20
                color: Styles.accent
                opacity: (root.player && root.player.canTogglePlaying) ? 1 : 0.5

                Icon {
                    anchors.centerIn: parent
                    icon: root.player && root.player.isPlaying ? "pause" : "play"
                    size: 18
                    tint: Styles.background
                }

                TapHandler {
                    onTapped: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                }
            }

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Styles.surfaceAlt
                opacity: (root.player && root.player.canGoNext) ? 1 : 0.4

                Icon {
                    anchors.centerIn: parent
                    icon: "skip-next"
                    size: 16
                    tint: Styles.foreground
                }

                TapHandler {
                    enabled: root.player && root.player.canGoNext
                    onTapped: root.player.next()
                }
            }

            IconButton {
                icon: "repeat"
                size: 20
                visible: root.player && root.player.loopSupported
                active: root.player && root.player.loopState !== MprisLoopState.None
                onClicked: {
                    root.player.loopState = root.player.loopState === MprisLoopState.None
                        ? MprisLoopState.Playlist
                        : (root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
                }
            }
        }

        // Sem player nenhum ativo, mostra uma dica em vez da tela ficar
        // vazia (a "capa" à esquerda já vira o ícone de nota musical nesse
        // caso, mas os controles continuam aparecendo desabilitados - isso
        // aqui só reforça por que estão assim).
        Text {
            visible: root.player === null
            text: "Nenhum player encontrado"
            color: Styles.foregroundMuted
            font.pixelSize: 11
            font.family: Styles.fontFamily
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
