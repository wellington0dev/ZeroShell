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

  Layout.alignment: Qt.AlignHCenter
  width: Styles.control
  height: 48
  color: Colors.moduleBG
  radius: 7

  border.width: 1
  border.color: Colors.borderColor

  property real temperature: 0

  Process {
    id: weatherProcess
    running: true
    command: ["curl", "-s", "https://wttr.in/?format=%t"]

    stdout: SplitParser {
      onRead: temp => {
        temperature = parseFloat(temp.replace(/[^\d.-]/g, ''));
      }
    }
  }

  Timer {
    interval: 1000000
    running: true
    repeat: true
    onTriggered: {
      weatherProcess.running = true;
    }
  }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 0

    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 4
      height: Styles.controlIconLarge
      Icon {
        anchors.centerIn: parent
        icon: "weather"
        size: Styles.controlIconLarge
        tint: Colors.gradientAccent2Color
      }
    }

    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.leftMargin: 5
      height: 20
      Text {
        anchors.centerIn: parent
        // "—" enquanto o curl do wttr.in não respondeu (ou falhou): mostrava
        // "0°" nos primeiros segundos, o que parece temperatura de verdade.
        text: temperature ? `${temperature}°` : "—"
        color: Colors.accent2Color
        font.family: Styles.fontFamily
        font.bold: true
        font.pixelSize: 11
      }
    }
  }
}
