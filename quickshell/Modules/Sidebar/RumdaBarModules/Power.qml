import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import qs.Theme
import qs.Widgets
import qs.Modules.Sidebar.RumdaConfig

Rectangle {
  id: root

  property string iconName: "power"
  property int moduleSize: Styles.control
  property int iconSize: Styles.controlIconLarge
  property int moduleRadius: Styles.radiusSmall

  Layout.alignment: Qt.AlignHCenter
  Layout.topMargin: 4

  height: moduleSize
  width: moduleSize
  radius: moduleRadius
  color: Colors.moduleBG
  border.width: 1
  border.color: Colors.borderColor

  Process {
    id: openDashboard
    // Abre o Dashboard pelo IPC dele. O Rumda escrevia no FIFO
    // /tmp/qs-dashboard.fifo, que não existe mais no shell.
    command: ["bash", "-c", "qs -c ~/.config/quickshell ipc call dashboard toggle"]
  }

  // Ícone pela cor do tema (Icon.qml do shell) em vez do SVG do Rumda com a
  // cor fixa embutida.
  Icon {
    id: icon
    anchors.centerIn: parent
    icon: root.iconName
    size: root.iconSize
    tint: Styles.foreground
    rotation: 0

    Behavior on rotation {
      NumberAnimation {
        duration: 800
        easing.type: Easing.OutBack
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      openDashboard.running = true;
      icon.rotation = icon.rotation + 360;
    }
  }
}
