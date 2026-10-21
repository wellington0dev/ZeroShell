import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import Quickshell.Bluetooth
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.Modules.Sidebar.RumdaConfig

Item {
  property int rowSpacing: 6
  // 32/20 (eram 40/26): com 5 botões a linha inteira tinha 224px e não cabia
  // no canto de um painel de ~250px sem encostar na saudação. São botões
  // secundários agora que a capa é o elemento principal do painel.
  readonly property int buttonSizes: 32
  readonly property int iconSizes: 20
  readonly property int buttonBorderWidth: 0
  readonly property int pfpRadius: 100
  readonly property int pfpSize: 160
  readonly property int buttonsGapFromBottom: 15
  readonly property int buttonFloatAmount: 4
  readonly property int topMarginOfText: 14

  // Saudação e usuário no canto superior ESQUERDO. Ficavam centralizados no
  // topo e agora que os botões foram para o canto direito eles encostariam
  // um no outro.
  Column {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: topMarginOfText
    spacing: 2

    Text {
      text: "Hello.."
      color: Colors.accentColor
      font.family: Styles.fontFamily
      font.pixelSize: 16
      font.bold: true
    }

    Text {
      text: Config.username
      color: Colors.accentColor
      font.family: Styles.fontFamily
      font.pixelSize: 18
      font.bold: true
    }
  }

  // ==========================================================================
  //  <<< AJUSTE AQUI >>>  BOTÕES QUE NÃO SÃO DO PLAYER
  // ==========================================================================
  //  Pasta, busca, captura de tela, terminal e bluetooth foram para o canto
  //  superior direito, e o miolo do painel ficou livre para a capa do player
  //  (DashPlayerCover.qml). Antes eles ficavam CENTRALIZADOS, que era
  //  exatamente onde a capa teve que entrar.
  //
  //  file: Modules/Dashboard/RumdaDashboard/DashControlExtras.qml (este arquivo)
  //  canto: "top" (padrão) / "bottom" - muda só a âncora
  //  folga:  topMarginOfText (14px) = distância até o topo do painel
  // ==========================================================================
  Row {
    id: extrasRow
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: topMarginOfText
    spacing: rowSpacing

    // folder button ==============================================
    Item {
      width: buttonSizes + buttonFloatAmount
      height: buttonSizes + buttonFloatAmount

    Process {
      id: process1
      // Gerenciador de arquivos: o Rumda chamava o "Config.fileManager"
      // dele (nautilus/yazi). Aqui é "xdg-open ~", que abre o gerenciador
      // padrão do sistema na pasta do usuário.
      command: ["bash", "-c", "xdg-open ~ &disown"]
      running: false
    }
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "folder"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          onClicked: process1.running = true
        }
    }

    // browser button ==============================================
    Item {
      width: buttonSizes + buttonFloatAmount
      height: buttonSizes + buttonFloatAmount

    Process {
      id: process2
      // "Pesquisar" no Rumda era o navegador; com "xdg-open" sem
      // argumento não acontecia nada de útil. Aqui abre o Launcher do
      // shell (IPC "launcher"), que é o buscador de verdade do shell.
      command: ["bash", "-c", "qs -c ~/.config/quickshell ipc call launcher toggle &disown"]
      running: false
    }
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "search"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          onClicked: process2.running = true
        }
    }

    // screenshot button ==============================================
    Item {
      width: buttonSizes + buttonFloatAmount
      height: buttonSizes + buttonFloatAmount

    Process {
      id: process3
      // Print de tela: o Rumda chamava "~/.config/rumda/scripts/
      // delayedScreenshot.sh". Aqui usa o módulo de captura do próprio
      // shell (Modules/Capture/CaptureService.qml), pelo IPC dele.
      command: ["bash", "-c", "qs -c ~/.config/quickshell ipc call capture toggle &disown"]
      running: false
    }
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "camera"
          size: buttonSizes
          iconSize: iconSizes
          tint: Colors.accentColor
          onClicked: process3.running = true
        }
    }

    // terminal button ==============================================
    Item {
      width: buttonSizes + buttonFloatAmount
      height: buttonSizes + buttonFloatAmount

    Process {
      id: process4
      // Terminal: o Config.terminal do Rumda apontava pro "alacritty",
      // que não está instalado nesta máquina. O terminal do shell é o
      // kitty (mesmo do ~/.config/kitty).
      command: ["/bin/sh", "-c", "kitty &disown"]
      running: false
    }
        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          icon: "terminal"
          size: buttonSizes
          iconSize: iconSizes
          tint: Styles.foreground
          onClicked: process4.running = true
        }
    }

    // bluetooth button ==============================================
    Item {
      // PLEASE note that I do not use bluetooth nor have it as a feature on my pc
      // so I have no idea whether or not this works.. sorry
      width: buttonSizes + buttonFloatAmount
      height: buttonSizes + buttonFloatAmount

        TileButton {
          width: buttonSizes
          height: buttonSizes
          anchors.verticalCenter: parent.verticalCenter
          size: buttonSizes
          iconSize: iconSizes
          // Ícone e cor seguem o estado do rádio (ligado/desligado), como o
          // WifiButton.qml do shell.
          icon: Bluetooth.adapter?.powered ? "bluetooth" : "bluetooth-off"
          tint: Bluetooth.adapter?.powered ? Styles.accent : Styles.foregroundMuted
          onClicked: {
            if (Bluetooth.adapter) {
              Bluetooth.adapter.powered = !Bluetooth.adapter.powered;
            } else {
              console.error("No bluetooth adapter found");
            }
          }
        }
    }
  }   // row 1 ends here

} // end of column that contains the 2 rows of buttons

