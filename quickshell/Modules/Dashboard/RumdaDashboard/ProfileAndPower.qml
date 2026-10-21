import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
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
  id: profileAndPowerRect

  readonly property int buttonSizes: 40 //51
  readonly property int buttonSpacing: 7
  readonly property int buttonBorderWidth: 0
  readonly property int pfpRadius: 100
  readonly property int pfpSize: 160
  readonly property int iconSizes: 23 //27
  // properties related to position / animation

  // ==========================================================================
  //  <<< AJUSTE AQUI >>>  DISTÂNCIA ENTRE A FOTO E OS BOTÕES
  // ==========================================================================
  //  Este é O número que move a coluna de botões (desligar/sair/reiniciar/
  //  travar/atalhos) na horizontal, em relação à foto.
  //
  //  file: Modules/Dashboard/RumdaDashboard/ProfileAndPower.qml (este arquivo)
  //  line: a linha logo abaixo do bloco
  //  valor: 26px
  //
  //  Medidas: a foto + o anel decorativo ocupam 200px (pfpSize 160 + 40), e o
  //  "spacing: 16" da Row abaixo soma mais 16. Então a distância real entre o
  //  anel da foto e o botão é: 16 (spacing) + este valor.
  //      26 -> ~42px de folga   (atual)
  //      20 -> ~36px
  //      14 -> ~30px
  //      8  -> ~24px
  //  Abaixo de ~10 os botões encostam no anel da foto. Para BASTA mudar este
  //  número; o hover acompanha sozinho (ver "buttonFloatAmount" logo abaixo).
  //
  //  Só mude por aqui. As "circular offsets" (middleButtonsCircularOffset /
  //  centerButtonCircularOffset, mais abaixo) são o ARCO dos botões em volta
  //  da foto e não mexem na distância - se mexer neles, o arco entorta.
  // ==========================================================================
  readonly property int allButtonsOffset: 12
  // "buttonFloatAmount" NÃO é "quanto o botão anda no hover": é a posição
  // FINAL dele no hover. O uso é
  //   leftMargin: hovered ? buttonFloatAmount : allButtonsOffset
  // ou seja, o botão flutua na DIREÇÃO da foto - no Rumda (21 -> 6) eram 15px.
  // Com "allButtonsOffset + 6" o movimento saía invertido: o botão se
  // afastava da foto no hover em vez de se aproximar.
  readonly property int buttonFloatAmount: allButtonsOffset - 15

  // dont concern urself with those, I use them to achieve a circular kinda layout
  readonly property int middleButtonsCircularOffset: 30
  readonly property int centerButtonCircularOffset: 10
  // =============================================================================

  color: Colors.dashModulesColor
  border.width: Config.dashInnerModuleBorderWidth
  border.color: Colors.borderColor
  radius: Config.dashInnerModuleRadius

  Row {
    id: pfpRow
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.top: parent.top
    anchors.margins: 20
    // Sem "width" fixa: a Row pega a largura do conteúdo (foto + coluna de
    // botões). Com a largura travada em pfpSize + 40 os botões ficavam fora da
    // caixa, e o painel do meio ("Hello..") encostava neles.
    //
    // Este "spacing" também conta na distância foto->botão (é somado ao
    // allButtonsOffset). Para mexer só na distância, mexa no "AJUSTE AQUI" do
    // allButtonsOffset e deixe este 16 como está.
    spacing: 0

    // Sem "anchors.left"/"anchors.verticalCenter" aqui: este Item é filho de
    // um Row (positioner), que já posiciona os filhos sozinho - e o Qt
    // avisa que âncora nesses eixos dentro de Row é comportamento indefinido
    // ("Row will not function").
    Item {
      width: pfpSize + 40
      height: pfpSize + 40

      // ==========================================================================
      //  <<< AJUSTE AQUI >>>  POSIÇÃO VERTICAL DA FOTO
      // ==========================================================================
      //  "y" desloca só o bloco da foto (círculo + anel + imagem) pra baixo,
      //  sem mexer na coluna de botões. Negativo sobe, positivo desce.
      //  O Row deixa os filhos em y = 0, então este é o deslocamento total.
      //      0  -> como estava (no topo)
      //      10 -> 10px mais baixo (atual)
      // ==========================================================================
      y: 10

      Item {
        width: pfpSize + 40
        height: pfpSize + 40

        Rectangle {
          anchors.centerIn: parent
          width: pfpSize + 40
          height: pfpSize + 40
          radius: width / 2
          color: Colors.dashPFPColor
        }
        Rectangle {
          anchors.centerIn: parent
          width: pfpSize + 23
          height: pfpSize + 23
          radius: width / 2
          color: "transparent"
          border.width: 3
          border.color: Colors.dashBorderColor
        }
        ClippingWrapperRectangle {
          anchors.centerIn: parent
          radius: pfpRadius
          width: pfpSize
          height: pfpSize

          Image {
            source: Config.profilePath
            sourceSize.width: pfpSize
            sourceSize.height: pfpSize
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            antialiasing: true
            smooth: true
          }
        }
      }
    }

    // A coluna dos botões fica depois da foto, centralizada na vertical. Não
    // pode usar "anchors.left"/"anchors.verticalCenter": este ColumnLayout é
    // filho do Row da foto, e âncora nesses eixos dentro de Row quebra a
    // posição do Row (o Qt avisa "Row will not function"). O Row já cuida do
    // eixo horizontal; a centralização vertical é feita pelo y.
    ColumnLayout {
      y: (pfpRow.height - height) / 2
      spacing: buttonSpacing

      Item {
        width: buttonSizes + buttonFloatAmount + allButtonsOffset
        height: buttonSizes

Process {
  id: process5
  command: ["systemctl", "poweroff"]
  running: false
}
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: hovered ? buttonFloatAmount : allButtonsOffset
          icon: "power"
          size: buttonSizes
          iconSize: iconSizes - 2
          tint: Styles.foreground
          onClicked: process5.running = true
        }
      }

      Item {
        width: buttonSizes + buttonFloatAmount + middleButtonsCircularOffset + allButtonsOffset
        height: buttonSizes

Process {
  id: process6
  command: ["hyprshutdown"]
  running: false
}
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: hovered ? buttonFloatAmount + middleButtonsCircularOffset : middleButtonsCircularOffset + allButtonsOffset
          icon: "logout"
          size: buttonSizes
          iconSize: iconSizes - 2
          tint: Styles.foreground
          onClicked: process6.running = true
        }
      }

      Item {
        width: buttonSizes + buttonFloatAmount + middleButtonsCircularOffset + centerButtonCircularOffset + allButtonsOffset
        height: buttonSizes

Process {
  id: processMiddle
  command: ["systemctl", "reboot"]
  running: false
}
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: hovered ? buttonFloatAmount + middleButtonsCircularOffset + centerButtonCircularOffset : middleButtonsCircularOffset + centerButtonCircularOffset + allButtonsOffset
          icon: "restart"
          size: buttonSizes
          iconSize: iconSizes + 1
          tint: Styles.foreground
          onClicked: processMiddle.running = true
        }
      }

      Item {
        width: buttonSizes + buttonFloatAmount + middleButtonsCircularOffset + allButtonsOffset
        height: buttonSizes

Process {
  id: process7
  command: ["qs", "ipc", "call", "lockscreen", "lock"]
  running: false
}
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: hovered ? buttonFloatAmount + middleButtonsCircularOffset : middleButtonsCircularOffset + allButtonsOffset
          icon: "lock"
          size: buttonSizes
          iconSize: iconSizes - 2
          tint: Styles.foreground
          onClicked: process7.running = true
        }
      }

      Item {
        width: buttonSizes + buttonFloatAmount + allButtonsOffset
        height: buttonSizes

Process {
  id: process8
  command: ["bash", "-c", "qs -c ~/.config/quickshell ipc call settings open keybinds"]
  running: false
}
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: hovered ? buttonFloatAmount : allButtonsOffset
          icon: "keyboard"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          onClicked: process8.running = true
        }
      }
    } // end of ColumnLayout for power buttons
  } // end of row that contains the pfp and buttons

  // normal straight position that animates left. this is nice, but I wanted smth different, so it's commented out
  //   ColumnLayout {
  //     anchors.right: parent.right
  //     anchors.verticalCenter: parent.verticalCenter
  //     spacing: buttonSpacing
  //
  //     // Square Button 1
  //     Item {
  //       width: buttonSizes + buttonFloatAmount
  //       height: buttonSizes
  //
  //       Rectangle {
  //         id: powerButton
  //         width: buttonSizes
  //         height: buttonSizes
  //         anchors.bottom: parent.bottom
  //         anchors.right: parent.right
  //         anchors.rightMargin: mouseArea1.containsMouse ? buttonFloatAmount : 0
  //         radius: Config.dashInnerModuleRadius
  //         color: mouseArea1.containsMouse ? Qt.alpha(Styles.accent, 0.22) : Colors.powerButtons
  //         border.width: buttonBorderWidth
  //         border.color: Colors.borderColor
  //
  //         Behavior on color {
  //           ColorAnimation { duration: 200 }
  //         }
  //
  //         Behavior on anchors.rightMargin {
  //           NumberAnimation { duration: 200 }
  //         }
  //
  //         MouseArea {
  //           id: mouseArea1
  //           anchors.fill: parent
  //           cursorShape: Qt.PointingHandCursor
  //           hoverEnabled: true
  //           onClicked: {
  //             process5.running = true
  //           }
  //         }
  //
  //         Process {
  //           id: process5
  //           command: ["/bin/sh", "-c", "shutdown"]
  //           running: false
  //         }
  //
  //         Image {
  //           anchors.centerIn: parent
  //           anchors.horizontalCenterOffset: 1
  //           width: iconSizes - 2
  //           height: iconSizes - 2
  //           source: `file://${Config.configPath}/light/icons/powerPix.svg`
  //           fillMode: Image.PreserveAspectFit
  //           antialiasing: true
  //           smooth: true
  //           mipmap: true
  //         }
  //       }
  //     }
  //
  //
  //
  //     // Square Button 2
  //     Item {
  //       width: buttonSizes + buttonFloatAmount
  //       height: buttonSizes
  //
  //       Rectangle {
  //         width: buttonSizes
  //         height: buttonSizes
  //         anchors.bottom: parent.bottom
  //         anchors.right: parent.right
  //         anchors.rightMargin: mouseArea2.containsMouse ? buttonFloatAmount : 0
  //         radius: Config.dashInnerModuleRadius
  //         color: mouseArea2.containsMouse ? Qt.alpha(Styles.accent, 0.22) : Colors.powerButtons
  //         border.width: buttonBorderWidth
  //         border.color: Colors.borderColor
  //
  //         Behavior on color {
  //           ColorAnimation { duration: 200 }
  //         }
  //
  //         Behavior on anchors.rightMargin {
  //           NumberAnimation { duration: 200 }
  //         }
  //
  //         MouseArea {
  //           id: mouseArea2
  //           anchors.fill: parent
  //           cursorShape: Qt.PointingHandCursor
  //           hoverEnabled: true
  //           onClicked: {
  //             process6.running = true
  //           }
  //         }
  //
  //         Process {
  //           id: process6
  //           command: ["/bin/sh", "-c", "loginctl terminate-user $USER"]
  //           running: false
  //         }
  //
  //         Image {
  //           anchors.centerIn: parent
  //           anchors.horizontalCenterOffset: 2
  //           width: iconSizes  - 2
  //           height: iconSizes - 2
  //           source: `file://${Config.configPath}/light/icons/logoutPix.svg`
  //           fillMode: Image.PreserveAspectFit
  //           antialiasing: true
  //           smooth: true
  //           mipmap: true
  //         }
  //       }
  //     }
  //
  //     // Square Button 3
  //     Item {
  //       width: buttonSizes + buttonFloatAmount
  //       height: buttonSizes
  //
  //       Rectangle {
  //         width: buttonSizes
  //         height: buttonSizes
  //         anchors.bottom: parent.bottom
  //         anchors.right: parent.right
  //         anchors.rightMargin: mouseArea3.containsMouse ? buttonFloatAmount : 0
  //         radius: Config.dashInnerModuleRadius
  //         color: mouseArea3.containsMouse ? Qt.alpha(Styles.accent, 0.22) : Colors.powerButtons
  //         border.width: buttonBorderWidth
  //         border.color: Colors.borderColor
  //
  //         Behavior on color {
  //           ColorAnimation { duration: 200 }
  //         }
  //
  //         Behavior on anchors.rightMargin {
  //           NumberAnimation { duration: 200 }
  //         }
  //
  //         MouseArea {
  //           id: mouseArea3
  //           anchors.fill: parent
  //           cursorShape: Qt.PointingHandCursor
  //           hoverEnabled: true
  //           onClicked: {
  //             process7.running = true
  //           }
  //         }
  //
  //         Process {
  //           id: process7
  //           command: ["bash", "-c", "hyprlock"]
  //           running: false
  //         }
  //
  //         Image {
  //           anchors.centerIn: parent
  //           width: iconSizes - 2
  //           height: iconSizes - 2
  //           source: `file://${Config.configPath}/light/icons/padlockPix.svg`
  //           fillMode: Image.PreserveAspectFit
  //           antialiasing: true
  //           smooth: true
  //           mipmap: true
  //         }
  //       }
  //     }
  //
  //     // Square Button 4
  //     Item {
  //       width: buttonSizes + buttonFloatAmount
  //       height: buttonSizes
  //
  //       Rectangle {
  //         width: buttonSizes
  //         height: buttonSizes
  //         anchors.bottom: parent.bottom
  //         anchors.right: parent.right
  //         anchors.rightMargin: mouseArea4.containsMouse ? buttonFloatAmount : 0
  //         radius: Config.dashInnerModuleRadius
  //         color: mouseArea4.containsMouse ? Qt.alpha(Styles.accent, 0.22) : Colors.powerButtons
  //         border.width: buttonBorderWidth
  //         border.color: Colors.borderColor
  //
  //         Behavior on color {
  //           ColorAnimation { duration: 200 }
  //         }
  //
  //         Behavior on anchors.rightMargin {
  //           NumberAnimation { duration: 200 }
  //         }
  //
  //         MouseArea {
  //           id: mouseArea4
  //           anchors.fill: parent
  //           cursorShape: Qt.PointingHandCursor
  //           hoverEnabled: true
  //           onClicked: {
  //             process8.running = true
  //           }
  //         }
  //
  //         Process {
  //           id: process8
  //           command: ["bash", "-c", "alacritty -e nvim ~/.config/rumda/README.md"]
  //           running: false
  //         }
  //
  //         Image {
  //           anchors.centerIn: parent
  //           width: iconSizes
  //           height: iconSizes
  //           source: `file://${Config.configPath}/light/icons/readmePix.svg`
  //           fillMode: Image.PreserveAspectFit
  //           antialiasing: true
  //           smooth: true
  //           mipmap: true
  //         }
  //       }
  //     }
  //   }
  // } // END OF COLUMN
}  // end of rectangle that contains this whole module (the bg rectangle)

