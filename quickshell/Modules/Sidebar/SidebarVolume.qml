import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Theme
import qs.Widgets
import qs.Modules.Volume

// Item de volume da sidebar (Fase 4).
//
// O QUE REAPROVEITA (nada de serviço novo):
//   - Pipewire.defaultAudioSink: o MESMO sink que o VolumePanel.qml:24 lê.
//     Nenhuma segunda conexão de áudio é aberta - só mais um consumidor.
//   - VolumeState: o MESMO singleton que a VolumeTrigger/VolumePanel já usam,
//     com o mesmo `open`. Abrir aqui é o mesmo abrir de lá.
//
// POR QUE O CLIQUE ABRE O PAINEL E NÃO AJUSTA DIRETO:
// O ajuste por scroll foi avaliado e descartado por medição, não por gosto:
// o Widgets/IconButton.qml (linhas 25-62) expõe só `clicked`, com um
// HoverHandler e um TapHandler - não tem WheelHandler nem `onMoved`. E NENHUM
// componente do shell usa WheelHandler (grep em todo ~/.config/quickshell não
// devolve nada). Então o scroll seria um idioma de interação INEXISTENTE aqui -
// o oposto de "consistente com os controles existentes". O ajuste continua no
// VolumePanel, cujo VerticalSlider (VolumePanel.qml:140) já faz isso.
//
// Ícones: só existem volume-high e volume-muted no shell (Icons/), e é
// exatamente a escolha que o VolumePanel.qml:131 já faz - não há como mostrar
// um nível intermediário sem inventar um ícone novo.
//
// Este componente é o CONTEÚDO do SidebarItem (o container visual é adicionado
// pelo Sidebar.qml via SidebarItem). Aqui só definimos o conteúdo interno.
// A raiz é o próprio ColumnLayout (e não um Item com "anchors.fill"):
// o SidebarItem dimensiona o conteúdo pelo implicitWidth/implicitHeight dele,
// então um Item de raiz - que sempre reporta implicit 0 - colapsaria o item
// inteiro da sidebar pra um quadradinho vazio.
ColumnLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.ready && sink.audio)
    readonly property bool muted: ready && sink.audio.muted
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property int percent: Math.round(volume * 100)

    spacing: Styles.spacing / 2

    IconButton {
        Layout.alignment: Qt.AlignHCenter

        icon: root.ready && root.muted ? "volume-muted" : "volume-high"
        size: 32
        // "active" acende o botão quando o painel de volume está aberto (o
        // mesmo feedback que launcher/settings/power usam com Visibility.*).
        active: VolumeState.open

        onClicked: VolumeState.open = !VolumeState.open
    }

    Text {
        Layout.alignment: Qt.AlignHCenter

        // Vazio (e não "0%") enquanto não há sink pronto: mostrar 0% sugeriria
        // "volume no zero", que é uma informação errada.
        text: root.ready ? (root.muted ? "—" : root.percent + "%") : ""
        color: root.muted && root.ready ? Styles.foregroundMuted : Styles.foreground
        font.pixelSize: Styles.fontSizeSmallest
        font.family: Styles.fontFamily
    }
}