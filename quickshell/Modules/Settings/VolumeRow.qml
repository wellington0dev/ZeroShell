import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Theme
import qs.Widgets

RowLayout {
    id: root

    property PwNode node

    readonly property bool ready: !!(node && node.ready && node.audio)

    spacing: Styles.spacing

    IconButton {
        size: 28
        icon: root.ready && node.audio.muted ? "volume-muted" : "volume-high"
        onClicked: if (root.ready) node.audio.muted = !node.audio.muted
    }

    Text {
        text: root.node ? (root.node.description || root.node.name) : "—"
        color: Styles.foreground
        font.pixelSize: 13
        font.family: Styles.fontFamily
        elide: Text.ElideRight
        Layout.preferredWidth: 160
    }

    Slider {
        Layout.fillWidth: true
        value: root.ready ? node.audio.volume : 0
        onMoved: (v) => { if (root.ready) node.audio.volume = v }
    }

    Text {
        text: root.ready ? Math.round(node.audio.volume * 100) + "%" : "—"
        color: Styles.foregroundMuted
        font.pixelSize: 11
        font.family: Styles.fontFamily
        Layout.preferredWidth: 34
    }
}
