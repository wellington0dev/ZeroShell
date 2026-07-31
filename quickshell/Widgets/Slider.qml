import QtQuick
import qs.Theme

// Barra deslizante genérica (0.0 a 1.0) - usada pra volume (VolumeRow) e pra
// posição/progresso da música (PlayerContent). Não tem noção de "o que"
// representa; quem usa é responsável por converter o valor 0..1 pra
// segundos, porcentagem, etc.
//
// "value" pode ser setado de fora (pra refletir o estado real, ex.: volume
// atual do sistema) via BINDING (ex.: "value: node.audio.volume") - e é só
// isso que deve escrever nele. O arrasto do mouse NUNCA escreve direto em
// "value": fazer isso destruiria o binding de fora pra sempre (é assim que
// QML funciona - uma atribuição imperativa a uma propriedade com binding
// derruba esse binding permanentemente, não só até a próxima leitura). Foi
// exatamente esse bug que deixava a barra de progresso do player (e a de
// volume) travada pra sempre depois do primeiro toque - visto ao vivo.
// Por isso o arrasto usa "dragValue" (property própria, sem binding de
// fora) só pro feedback visual imediato enquanto "pressed" é true; ao
// soltar, volta a mostrar "value" direto (que a essa altura já devia
// refletir o valor novo, já que "moved()"/"released()" pedem pra quem usa
// aplicar de verdade - ex.: node.audio.volume = v).
//
// "moved()" dispara a CADA movimento do mouse durante o arrasto (bom pra
// coisas baratas, tipo volume) - "released()" dispara só UMA vez, ao soltar
// o botão, com o valor final. Importante pra quem usa ter uma ação cara
// (ex.: PlayerContent.qml chamando player.position = ... pra buscar posição
// via MPRIS): usar "moved()" pra isso significa mandar dezenas de comandos
// de busca por segundo enquanto o usuário arrasta - visto ao vivo travando/
// engasgando o vídeo (várias buscas de posição em sequência rápida). Quem só
// precisa de feedback visual barato (a barra de volume) pode continuar
// usando "moved()"; quem tem uma ação cara deve usar "released()".
Item {
    id: root

    property real value: 0 // 0..1, ligado de fora
    property real dragValue: 0
    readonly property real displayValue: pressed ? dragValue : value
    readonly property bool pressed: mouseArea.pressed

    signal moved(real value)
    signal released(real value)

    implicitHeight: 16
    implicitWidth: 120

    // Converte uma posição X do mouse (em pixels) pra um valor 0..1 e aplica.
    function setFromX(x) {
        const v = Math.max(0, Math.min(1, x / root.width))
        root.dragValue = v
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
        color: Styles.surfaceAlt

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, root.displayValue))
            height: parent.height
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
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(1, root.displayValue)) * (root.width - width)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: (mouse) => root.setFromX(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) root.setFromX(mouse.x) }
        onReleased: root.released(root.dragValue)
    }
}
