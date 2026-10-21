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
import qs.State
import qs.Widgets
import qs.Modules.Sidebar.RumdaConfig
import qs.Modules.Sidebar.RumdaBarModules
import qs.Modules.Dashboard

// TopSection da SidebarNew: foto de perfil, relógio (expande pra data no
// hover), volume e os anéis de CPU/RAM.
//
// É o topo da coluna em TOPO/CENTRO/RODAPÉ do SidebarNew.qml, então a caixa
// aqui é transparente: cada módulo (Relógio/Volume/CPU) é o seu próprio
// "Rectangle" desenhado logo abaixo.
Rectangle {
  id: root

  // Foto de perfil: o "ProfilePicture" mora em "qs.Modules.Sidebar" e este
  // arquivo é um sub-módulo (RumdaBarSections), que não pode importar o módulo
  // pai - o pai é justamente o SidebarNew.qml, que importa ESTE módulo, e aí
  // viraria ciclo. Quem monta o Component é o SidebarNew.qml (que enxerga os
  // dois sem ciclo) e este arquivo só o recebe.
  property Component profileComponent: null

  property string currentTime: Qt.formatDateTime(new Date(), "hh:mm")
  property string currentHours: Qt.formatDateTime(new Date(), "hh")
  property string currentMinutes: Qt.formatDateTime(new Date(), "mm")
  property string currentMonth: Qt.formatDateTime(new Date(), "MM")
  property string currentDay: Qt.formatDateTime(new Date(), "dd")

  Layout.fillWidth: true
  // A caixa tem exatamente a altura do conteúdo + 12 de respiro. Antes o
  // ColumnLayout vinha com "anchors.topMargin: 29" (herança da barra HORIZONTAL
  // do Rumda) enquanto a caixa era dimensionada por esse mesmo conteúdo: os 29
  // faziam o conteúdo transbordar 17px pra fora da caixa.
  Layout.preferredHeight: modules.implicitHeight + 12
  Behavior on Layout.preferredHeight {
    NumberAnimation {
      duration: 1000
      easing.type: Easing.InOutQuart
    }
  }

  color: "transparent"

  property real innerModulesRadius: 3

  // CPU/RAM vêm do singleton SystemStats (Modules/Dashboard/SystemStats.qml) - o
  // MESMO que a aba "Sistema" do Dashboard e o Modules/Sidebar/SidebarCpu.qml
  // consomem: um processo a cada 3s no total, em vez de dois a cada 1s aqui.
  //
  // Antes este arquivo rodava os comandos do próprio Rumda:
  //   top -bn1 | grep '%Cpu(s):' | awk '{print $2}'
  //   free | grep Mem: | awk '{printf "%.0f", ($2-$7)/$2*100}'
  // e NENHUM dos dois devolvia nada nesta máquina: com o sistema em pt_BR o
  // procps imprime "%CPU(s):" (maiúsculas) e o free imprime "Mem.:" (com
  // ponto), então os greps não casavam. Pior: os números saem com vírgula
  // decimal ("27,3"), que o parseFloat corta em "27". O resultado eram dois
  // anéis sempre vazios, só com o anel de fundo.
  readonly property int cpuPercent: SystemStats.cpuPercent
  readonly property int ramPercent: SystemStats.ramPercent

  ColumnLayout {
    id: modules
    property bool expanded: false

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    spacing: 6

    // ---- Foto de perfil ----
    // O Loader repassa o tamanho do item carregado; "width"/"height" (e não
    // "implicitWidth"/"implicitHeight", que no Loader são somente-leitura) é o
    // que dá a medida certa pro ColumnLayout.
    Loader {
      id: profileLoader
      Layout.alignment: Qt.AlignHCenter
      sourceComponent: root.profileComponent
      visible: status === Loader.Ready && item !== null
      width: item ? item.implicitWidth : 0
      height: item ? item.implicitHeight : 0
    }

    // ---- Relógio (vira data no hover) ----
    // Os Timers ficam aqui dentro porque "Timer" não é um Item: não entra na
    // conta do layout.
    Timer {
      interval: 60000
      running: true
      repeat: true
      onTriggered: {
        currentMonth = Qt.formatDateTime(new Date(), "MM");
        currentDay = Qt.formatDateTime(new Date(), "dd");
      }
    }
    Timer {
      interval: 1000
      running: true
      repeat: true
      onTriggered: {
        currentTime = Qt.formatDateTime(new Date(), "hh:mm");
        currentHours = Qt.formatDateTime(new Date(), "hh");
        currentMinutes = Qt.formatDateTime(new Date(), "mm");
      }
    }

    Rectangle {
      id: clockBox
      // As chaves "show*" vêm das Configurações (Modules/Settings/SidebarPage).
      // Só o "Sidebar.qml" antigo lia elas; com a barra do Rumda elas
      // ficaram órfãs e os interruptores não faziam nada.
      visible: SidebarConfig.showClock
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: modules.expanded ? 80 : 45
      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: 250
          easing.type: Easing.InOutQuad
        }
      }
      width: Styles.control
      radius: 7
      border.width: 1
      border.color: Colors.borderColor
      color: Colors.moduleBG

      Loader {
        anchors.centerIn: parent
        sourceComponent: modules.expanded ? dateComponent : clockComponent
      }

      Component {
        id: clockComponent
        ColumnLayout {
          spacing: 4
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentHours
            color: Colors.gradientAccent2Color
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmallest
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentMinutes
            color: Colors.gradientAccent2Color
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmallest
          }
        }
      }

      Component {
        id: dateComponent
        ColumnLayout {
          spacing: 4
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentDay
            color: Colors.gradientAccent2Color
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmallest
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentMonth
            color: Colors.gradientAccent2Color
            font.family: Styles.fontFamily
            font.pixelSize: Styles.fontSizeSmallest
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: modules.expanded = true
        onExited: modules.expanded = false
      }
    }

    // ---- Volume ----
    VolumeControl {
      visible: SidebarConfig.showVolume
    }

    // ---- CPU / RAM ----
    Rectangle {
      id: cpuBox
      visible: SidebarConfig.showCpu
      Layout.alignment: Qt.AlignHCenter
      width: 28
      // Os dois anéis (24 cada) + o espaçamento entre eles: a caixa acompanha
      // o conteúdo em vez de um número solto que could overflow.
      Layout.preferredHeight: rings.implicitHeight + 4
      radius: 7
      color: Colors.moduleBG

      border.width: 1
      border.color: Colors.borderColor

      ColumnLayout {
        id: rings
        Layout.alignment: Qt.AlignHCenter
        spacing: 2

        // CPU indicator
        RadialIndicator {
          Layout.alignment: Qt.AlignHCenter
          percent: root.cpuPercent
          indicatorColor: Colors.accentColor
          // Fundo do anel: "surfaceAlt" e não o accent - antes o fundo e o
          // arco usavam dois tons quase iguais (indicatorBGColor/accentColor),
          // então o arco quase não aparecia.
          backgroundColor: Styles.surfaceAlt
          size: Styles.controlRing
        }

        // RAM indicator
        RadialIndicator {
          Layout.alignment: Qt.AlignHCenter
          percent: root.ramPercent
          indicatorColor: Colors.accent2Color
          backgroundColor: Styles.surfaceAlt
          size: 24
        }
      }
    }
  }
}