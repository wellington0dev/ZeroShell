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
import qs.Modules.Sidebar.RumdaBarModules

Rectangle {
  id: root
  signal barDarkAnimate
  function themeClicked() {
    barDarkAnimate();
  }
  Layout.fillWidth: true
  Layout.preferredHeight: childrenRect.height + 8
  color: "transparent"
  property real innerModulesRadius: 3

  // Date/time formatting
  property string currentTime: Qt.formatDateTime(new Date(), "hh:mm")
  property string currentHours: Qt.formatDateTime(new Date(), "hh")
  property string currentMinutes: Qt.formatDateTime(new Date(), "mm")

  property string username: ""

  Process {
    command: ["whoami"]
    running: true
    stdout: SplitParser {
      onRead: name => username = name
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

  Behavior on height {
    NumberAnimation {
      duration: 1000
      easing.type: Easing.InOutQuart
    }
  }

  // Botão de Wi-Fi do shell, injetado pelo SidebarNew (ver comentário do
  // Loader mais abaixo).
  property Component wifiComponent

  ColumnLayout {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2
    spacing: 6

    ThemeSwitch {
      visible: SidebarConfig.showTheme
      onThemeDarkChanged: themeClicked()
    }

    // Clima não tem interruptor próprio na página da barra (o item do Rumda
    // não estava na lista) - fica sempre visível.
    WeatherStatus {}

    // Wi-Fi: o botão é o WifiButton.qml do PRÓPRIO shell (ícone por faixa de
    // força de sinal + toggle pra aba Wi-Fi das Configurações). Estava
    // substituído pelo InternetConnection do Rumda, que é só um ícone
    // conectado/desconectado e não tem nenhum dos dois comportamentos.
    //
    // Ele vem por "Component" porque o WifiButton mora em "qs.Modules.Sidebar"
    // (que importa esta seção) - importar de volta aqui seria ciclo. É o
    // mesmo esquema do "profileComponent" da TopSection.
    // O botão do shell é transparente até o hover (é o estilo dele, igual na
    // sidebar antiga), então ganha a mesma caixa dos tiles do Rumda ao redor -
    // mesma medida, mesmo raio, mesma borda, sem mudar o comportamento.
    Rectangle {
      id: wifiTile
      visible: SidebarConfig.showWifi
      Layout.alignment: Qt.AlignHCenter
      width: Styles.control
      height: Styles.control
      radius: Styles.radiusSmall
      // Mesma cor dos tiles do Rumda ao redor ("Colors.moduleBG", que é o
      // "Styles.surface"). Com "transparent" aparecia o fundo da barra, mais
      // escuro, e o tile de Wi-Fi ficava com cara de buraco na coluna.
      color: Styles.surface
      border.width: 1
      border.color: Styles.border

      Loader {
        anchors.centerIn: parent
        sourceComponent: root.wifiComponent
        width: parent.width
        height: parent.height
      }
    }
    Power {
      visible: SidebarConfig.showPower
    }
  }
}
