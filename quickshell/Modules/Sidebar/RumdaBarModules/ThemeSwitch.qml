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
  id: themeSwitchButton

  readonly property string iconPath: Config.configPath + "/light/icons"

  // Medida dos tiles vem do Styles (era 26 aqui, 28 nos vizinhos e 30 em
  // outros - na mesma barra).
  readonly property int moduleSize: Styles.control
  readonly property int imageSourceSize: 55
  readonly property int maskWidth: 20
  readonly property int maskHeight: 18
  readonly property int maskRadius: 8

  Layout.alignment: Qt.AlignHCenter
  Layout.topMargin: 4
  Layout.bottomMargin: 2

  width: moduleSize
  height: moduleSize
  radius: innerModulesRadius
  color: "transparent"

  // Era "Image" + OpacityMask (3 props só pra máscara). O Icon.qml do shell
  // pinta o SVG pela cor do tema e não precisa de máscara nenhuma.
  // Sinal que a BottomSection vertical escuta (o "onThemeDarkChanged").
  signal themeDarkChanged

  Icon {
    id: themeSwitchIcon
    anchors.centerIn: parent
    icon: "theme-switch"
    size: 18
    tint: Styles.foreground
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      themeDarkChanged();
      // O Rumda chamava "wall.sh dark"/"hyprtheme.sh dark" (scripts do
      // Rumda, com o modo FIXO em dark). Aqui é o mesmo método do botão de
      // tema da barra vertical: persiste o modo e roda o apply-theme.sh, que
      // regera o colors.json.
      Styles.applyColorMode(Styles.colorMode === "dark" ? "light" : "dark");
    }
  }
}
