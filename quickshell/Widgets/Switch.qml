import QtQuick
import qs.Theme

// Toggle estilo iOS/Android (trilho + bolinha que desliza).
//
// É um "componente controlado": ele NÃO muda o próprio "checked" sozinho ao
// ser clicado. Só emite "toggled()" e espera quem o usa decidir o novo valor
// e reatribuir "checked" de fora, ex.:
//
//   Switch {
//       checked: Colors.useWallpaperColors
//       onToggled: Colors.setUseWallpaperColors(!Colors.useWallpaperColors)
//   }
//
// Por quê? Porque na maioria dos usos (Wi-Fi ligado/desligado, Bluetooth,
// "usar cores do wallpaper"...) o valor real mora em outro lugar (um serviço,
// um arquivo). Se o Switch guardasse seu próprio estado internamente, teria
// duas fontes de verdade brigando entre si.
Item {
    id: root

    property bool checked: false

    signal toggled()

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colors.accent : Colors.surfaceAlt
        border.color: Colors.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        // A bolinha - desliza entre a esquerda (desligado) e a direita (ligado).
        Rectangle {
            width: parent.height - 4
            height: width
            radius: width / 2
            color: Colors.background
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }

    TapHandler { onTapped: root.toggled() }
}
