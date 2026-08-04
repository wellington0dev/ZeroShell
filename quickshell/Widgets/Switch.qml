import QtQuick
import qs.Theme

// Toggle estilo iOS/Android (trilho + bolinha que desliza).
//
// É um "componente controlado": ele NÃO muda o próprio "checked" sozinho ao
// ser clicado. Só emite "toggled()" e espera quem o usa decidir o novo valor
// e reatribuir "checked" de fora, ex.:
//
//   Switch {
//       checked: Styles.useWallpaperColors
//       onToggled: Styles.setUseWallpaperColors(!Styles.useWallpaperColors)
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
        color: root.checked ? Styles.accent : Styles.surfaceAlt
        border.color: Styles.border
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
        }

        // A bolinha - desliza entre a esquerda (desligado) e a direita (ligado).
        Rectangle {
            width: parent.height - 4
            height: width
            radius: width / 2
            color: Styles.background
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2

            Behavior on x {
                NumberAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveFastSpatial }
            }
        }
    }

    TapHandler { onTapped: root.toggled() }
}
