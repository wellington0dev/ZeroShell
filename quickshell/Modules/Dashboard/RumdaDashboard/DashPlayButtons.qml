import QtQuick.Shapes
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick.Window
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.Theme
import qs.Widgets
import qs.Modules.Player
import qs.Modules.Sidebar.RumdaConfig
import qs.Modules.Dashboard.RumdaDashboard

Row {
  id: dashPlayButtons

  property int rowSpacing: 6
  readonly property int buttonSizes: 40
  readonly property int iconSizes: 26
  readonly property int buttonBorderWidth: 0
  readonly property int pfpRadius: 100
  readonly property int pfpSize: 160
  readonly property int buttonsGapFromBottom: 15
  readonly property int buttonFloatAmount: 4
  // Sem "anchors.bottom": o pai posiciona com "anchors.centerIn" agora
  // (DashBoardControls.qml), e âncora nos dois eixos ao mesmo tempo é
  // comportamento indefinido.

  // Player: MPRIS direto (Modules/Player/Player.qml, o mesmo do PlayerTab e do
  // Dock do shell). Antes eram 4 processos de "playerctl" - e o "playerctl
  // status" era polido a cada 500ms, ou seja, dois processos por segundo,
  // eternamente, só para saber se o player está tocando.
  readonly property bool isPlaying: {
    const p = Player.active
    return !!p && p.isPlaying
  }

  function actPrevious() {
    const p = Player.active
    if (p) p.previous()
  }

  function actPlayPause() {
    const p = Player.active
    if (!p) return
    if (p.isPlaying) p.pause()
    else p.play()
  }

  function actNext() {
    const p = Player.active
    if (p) p.next()
  }

  // // Header
  // Row {
  //   anchors.horizontalCenter: parent.horizontalCenter
  //   Text {
  //     text: "media controls"
  //     color: Colors.accentColor
  //     font.pixelSize: 16
  //     font.bold: true
  //   }
  // }

  Item {
    id: mediaControlWrapper
    width: (buttonSizes + buttonFloatAmount) * 3 + rowSpacing * 2
    height: buttonSizes + buttonFloatAmount + 20

    property var player: Player.active

    Row {
      anchors.fill: parent
      spacing: rowSpacing
      Item {
        width: buttonSizes + buttonFloatAmount
        height: buttonSizes + buttonFloatAmount

        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "skip-previous"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          hoverScale: -0.05
          onClicked: actPrevious()
        }
      }

      Item {
        width: buttonSizes
        height: buttonSizes + buttonFloatAmount

        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          // Play/pause: o ícone acompanha o estado (era triário no original).
          icon: isPlaying ? "pause" : "play"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          // Este é o único que CRESCE no hover (1.05) em vez de encolher.
          hoverScale: +0.05
          onClicked: actPlayPause()
        }
      }

      Item {
        width: buttonSizes + buttonFloatAmount
        height: buttonSizes + buttonFloatAmount

        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "skip-next"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          hoverScale: -0.05
          onClicked: actNext()
        }
      }
    }
  }
}
