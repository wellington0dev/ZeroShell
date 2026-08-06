import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Theme
import qs.Widgets
import qs.State

// Card de volume que desliza a partir da borda direita, no meio vertical da
// tela - abre ao passar o mouse na faixa sensível (VolumeTrigger.qml) ou ao
// ficar em cima do próprio card (pra não fechar no meio do caminho ao mover
// o mouse da faixa até o slider). Minimalista de propósito: só ícone
// (mudo/volume, clicável) + barra vertical, sem título/nome de
// dispositivo/porcentagem - só instantâneo.
//
// Mesma técnica de slide do DashboardWindow.qml: ligação declarativa direta
// com VolumeState.open (não um reset manual + Qt.callLater/Timer feito à
// mão) - testado ao vivo que a versão manual quebra a animação (ver
// histórico do Launcher).
PanelWindow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.ready && sink.audio)

    // "anim.shouldBeVisible" (NUNCA "VolumeState.open" direto) - sem isso, a
    // superfície inteira (90x768, ancorada na borda direita) continuava
    // existindo e recebendo hover mesmo com o card deslizado pra fora da
    // tela - já que ela é declarada DEPOIS do VolumeTrigger.qml em
    // shell.qml, ficava por cima dele e roubava o hover da faixa sensível
    // (visto ao vivo: a faixa parava de reagir ao mouse). Mesmo motivo do
    // "visible: Visibility.launcherOpen" no LauncherWindow.qml - só que lá
    // era óbvio (a janela cobre a tela toda), aqui passou despercebido
    // porque a superfície é fininha e o "card" por dentro já escondia a
    // aparência, mas a área de clique/hover continuava lá. "shouldBeVisible"
    // (em vez de ligar direto em "open") também evita desmapear a
    // superfície ANTES do slide terminar - ver comentário em
    // Widgets/PanelAnim.qml.
    visible: anim.shouldBeVisible

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        right: true
    }

    // Sem isto, a superfície INTEIRA (90px de largura, borda direita de
    // cima a baixo) aceita clique/hover mesmo na parte transparente ao
    // redor do card - o EXATO bug que o comentário acima já descreve ter
    // acontecido antes (a superfície inteira roubando o hover do
    // VolumeTrigger.qml). Antes "visible: VolumeState.open" bastava porque
    // desmapeava na hora; agora que "shouldBeVisible" mantém a superfície
    // viva um pouco mais (pro slide terminar), essa máscara é o que evita a
    // mesma história se repetir só durante essa cauda.
    mask: Region { item: card }

    implicitWidth: 90

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Tipo/velocidade da animação de abrir/fechar vêm de
    // Configurações > Aparência > Animações (Motion.animationType) - ver
    // Widgets/PanelAnim.qml.
    PanelAnim {
        id: anim
        open: VolumeState.open
        edge: "right"
        distance: card.width
    }

    Shadow { target: card }

    Rectangle {
        id: card

        readonly property int restMargin: Styles.edgeMargin

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: restMargin + anim.slideOffset
        opacity: anim.targetOpacity
        scale: anim.targetScale
        transformOrigin: Item.Right
        width: 56
        height: 200
        radius: Styles.radiusShell
        color: Styles.background
        border.color: Styles.border
        border.width: 2

        // Mesma curva do slide do Dashboard (Motion.standard) - pedido pra
        // ficar igual em todos os painéis, não cada um com a sua.
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standard
            }
        }
        // durationNormal (não durationFast) de propósito - mesma duração do
        // slide (anchors.rightMargin, também durationNormal): sincronizado
        // assim, senão a opacidade chegava a 0 antes do slide terminar e o
        // card sumia (fade) bem antes de acabar de deslizar pra fora - a
        // segunda metade do movimento ficava invisível, sem ninguém ver.
        Behavior on opacity { NumberAnimation { duration: Motion.durationNormal } }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.boing
            }
        }

        HoverHandler {
            onHoveredChanged: VolumeState.hoveringPanel = hovered
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing * 1.5
            spacing: Styles.spacing

            IconButton {
                Layout.alignment: Qt.AlignHCenter
                icon: root.ready && root.sink.audio.muted ? "volume-muted" : "volume-high"
                size: 22
                onClicked: if (root.ready) root.sink.audio.muted = !root.sink.audio.muted
            }

            VerticalSlider {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                value: root.ready ? root.sink.audio.volume : 0
                onMoved: (v) => { if (root.ready) root.sink.audio.volume = v }
            }
        }
    }
}
