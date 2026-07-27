import QtQuick
import qs.Theme

// Barra deslizante genérica (0.0 a 1.0) - usada pra volume (VolumeRow) e pra
// posição/progresso da música (PlayerWindow). Não tem noção de "o que"
// representa; quem usa é responsável por converter o valor 0..1 pra
// segundos, porcentagem, etc.
//
// "value" pode ser setado de fora (pra refletir o estado real, ex.: volume
// atual do sistema) e o próprio arrastar do mouse também atualiza "value" na
// hora (feedback imediato), emitindo "moved()" pra quem estiver ouvindo
// aplicar a mudança de verdade (ex.: setar o volume do PipeWire).
Item {
    id: root

    property real value: 0 // 0..1

    signal moved(real value)

    implicitHeight: 16
    implicitWidth: 120

    // Converte uma posição X do mouse (em pixels) pra um valor 0..1 e aplica.
    function setFromX(x) {
        const v = Math.max(0, Math.min(1, x / root.width))
        root.value = v
        root.moved(v)
    }

    // O trilho: uma barra cinza de fundo com uma barra colorida por cima
    // representando o progresso preenchido.
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Colors.surfaceAlt

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Colors.accent
        }
    }

    // A bolinha que marca a posição atual em cima do trilho.
    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: Colors.foreground
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(1, root.value)) * (root.width - width)
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.setFromX(mouse.x)
        onPositionChanged: if (pressed) root.setFromX(mouse.x)
    }
}
