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
import qs.Modules.Sidebar.RumdaConfig
import qs.Modules.Dashboard.RumdaDashboard

Rectangle {
  property int columnSpacing: 6
  readonly property int buttonSizes: 40
  readonly property int middleButtonHeight: 100 // extra height that the middle button has
  readonly property int iconSizes: 26
  readonly property int brightnessTextSize: 9
  readonly property int buttonBorderWidth: 0
  readonly property int buttonFloatAmount: 4
  // brightness control stuff (im sleep deprived)
  property bool useDdcutil: false
  property bool brightnessChecked: false

  color: Colors.dashModulesColor
  border.width: Config.dashInnerModuleBorderWidth
  border.color: Colors.borderColor
  radius: Config.dashInnerModuleRadius

  Component.onCompleted: {
    brightnessDetector.running = true;
  }

  Process {
    id: brightnessDetector
    command: ["sh", "-c", "brightnessctl -c backlight info 2>/dev/null"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        if (data.trim().length > 0) {
          useDdcutil = false;
          console.log("Using brightnessctl for backlight");
        }
        brightnessChecked = true;
      }
    }

    onExited: code => {
      if (code !== 0) {
        useDdcutil = true;
        console.log("Using ddcutil for external monitor");
        brightnessChecked = true;
      }
    }
  }

  // Era um "Column" só pra servir de moldura: o único filho dele se ancora em
  // horizontal/verticalCenter, e âncora nesses eixos dentro de Column/Row é
  // comportamento indefinido no Qt ("Column will not function"). Um Item não
  // posiciona os filhos, então as âncoras valem de novo.
  Item {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    width: buttonSizes
    height: ((buttonSizes + buttonFloatAmount) * 2 + brightnessDisplayRect.height + columnSpacing * 2) + 20

    Item {
      id: brightnessControlWrapper
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: parent.height

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: columnSpacing

        Item {
          width: buttonSizes
          height: buttonSizes + buttonFloatAmount

          Process {
            id: processBrightnessUp
            command: useDdcutil ? ["ddcutil", "setvcp", "10", "+", "10"] : ["brightnessctl", "-c", "backlight", "set", "10%+"]
            running: false
          }
          // Sobe no hover e encolhe - o "flutuar" que o Rumda fazia mexendo o
          // "anchors.topMargin" do botão inteiro.
          TileButton {
            width: buttonSizes
            height: buttonSizes
            icon: "chevronUP"
            size: buttonSizes
            iconSize: iconSizes - 2
            tint: Styles.foreground
            hoverOffset: buttonFloatAmount
            onClicked: processBrightnessUp.running = true
          }
        }

        Rectangle {
          id: brightnessDisplayRect
          width: buttonSizes
          height: buttonSizes + middleButtonHeight  // i could use a layout but im too sleep deprived imma hardcode this rq (sorry)
          radius: Config.dashInnerModuleRadius
          color: mouseAreaBrightnessDisplay.containsMouse ? Qt.alpha(Styles.accent, 0.22) : Colors.powerButtons
          border.width: buttonBorderWidth
          border.color: Colors.borderColor
          scale: mouseAreaBrightnessDisplay.containsMouse ? 1.05 : 1.0

          Behavior on scale {
            NumberAnimation {
              duration: 200
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: 200
            }
          }

          MouseArea {
            id: mouseAreaBrightnessDisplay
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
          }

          // Item em vez de Column: os filhos daqui se ancoram em centerIn.
          Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height

            Icon {
            anchors.centerIn: parent
            icon: "brightness"
            size: iconSizes
            tint: Styles.foreground
          }

            Text {
              id: brightnessText
              anchors.horizontalCenter: parent.horizontalCenter
              text: brightnessValue
              color: mouseAreaBrightnessDisplay.containsMouse ? Colors.dashModulesColor : Colors.accent2Color
              font.pixelSize: brightnessTextSize
              font.bold: false

              Behavior on color {
                ColorAnimation {
                  duration: 200
                }
              }

              property string brightnessValue: "50%"

              Process {
                id: brightnessReader
                command: ["sh", "-c", "brightnessctl -c backlight 2>/dev/null | grep -oP '\\(\\K[0-9]+(?=%\\))' || ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\\s+\\K[0-9]+'"]
                running: true

                stdout: SplitParser {
                  onRead: data => {
                    brightnessText.brightnessValue = data.trim();
                  }
                }
              }

              Timer {
                interval: 500
                running: true
                repeat: true
                onTriggered: brightnessReader.running = true
              }
            }
          }
        }

        Item {
          width: buttonSizes
          height: buttonSizes + buttonFloatAmount

          Process {
            id: processBrightnessDown
            command: useDdcutil ? ["ddcutil", "setvcp", "10", "-", "10"] : ["brightnessctl", "-c", "backlight", "set", "10%-"]
            running: false
          }
          // Desce no hover - por isso o "hoverOffset" negativo.
          TileButton {
            width: buttonSizes
            height: buttonSizes
            icon: "chevronDOWN"
            size: buttonSizes
            iconSize: iconSizes - 2
            tint: Styles.foreground
            hoverOffset: -buttonFloatAmount
            onClicked: processBrightnessDown.running = true
          }
        }
      }
    }
  }
}
