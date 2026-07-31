import QtQuick
import qs.Theme

// Versão vertical do Slider.qml (0.0 embaixo, 1.0 em cima - como qualquer
// controle de volume vertical) - usada pelo VolumePanel.qml. Mesma técnica
// de binding do Slider.qml (ver comentário lá pro motivo): "value" só é
// escrito de fora via binding, o arrasto usa "dragValue" à parte pra não
// quebrar esse binding.
Item {
    id: root

    property real value: 0 // 0..1, ligado de fora
    property real dragValue: 0
    readonly property real displayValue: pressed ? dragValue : value
    readonly property bool pressed: mouseArea.pressed

    signal moved(real value)
    signal released(real value)

    implicitWidth: 16
    implicitHeight: 120

    // Converte uma posição Y do mouse (em pixels) pra um valor 0..1 - Y
    // cresce pra BAIXO na tela, então inverte (0 no fundo, 1 no topo).
    function setFromY(y) {
        const v = Math.max(0, Math.min(1, 1 - y / root.height))
        root.dragValue = v
        root.moved(v)
    }

    // O trilho: uma barra cinza de fundo com uma barra colorida por baixo
    // (crescendo de baixo pra cima) representando o volume preenchido.
    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        width: 6
        height: parent.height
        radius: 3
        color: Styles.surfaceAlt

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: track.height * Math.max(0, Math.min(1, root.displayValue))
            radius: parent.radius
            color: Styles.accent
        }
    }

    // A bolinha que marca a posição atual em cima do trilho.
    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: Styles.foreground
        anchors.horizontalCenter: parent.horizontalCenter
        y: (1 - Math.max(0, Math.min(1, root.displayValue))) * (root.height - height)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: (mouse) => root.setFromY(mouse.y)
        onPositionChanged: (mouse) => { if (pressed) root.setFromY(mouse.y) }
        onReleased: root.released(root.dragValue)
    }
}
