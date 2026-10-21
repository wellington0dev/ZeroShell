import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.Modules.Sidebar.RumdaConfig
import qs.Modules.Dashboard.RumdaDashboard

Rectangle {
  id: brightnessRect
  readonly property int buttonSizes: 51
  readonly property int buttonSpacing: 7
  readonly property int buttonBorderWidth: 0
  readonly property int buttonsGapFromBottom: 15
  readonly property int iconSizes: 27
  readonly property int buttonFloatAmount: 6

  color: Colors.dashModulesColor
  border.width: Config.dashInnerModuleBorderWidth
  border.color: Colors.borderColor
  radius: Config.dashInnerModuleRadius

  // Três faixas com altura definida, em vez do GridLayout 9x6 do Rumda.
  //
  // No GridLayout a capa ficava CENTRALIZADA dentro de uma célula que recebia
  // a sobra do espaço por proporção - e como a célula da capa era maior que a
  // soma capa + título/artista, o texto embaixo da capa ficava por baixo dos
  // botões de play (conferido no screenshot). Aqui a faixa do meio é a única
  // que estica, e a capa se limita à altura que sobrar (ela lê a altura do
  // pai, ver DashPlayerCover.qml).
  ColumnLayout {
    // Margem e espaçamento apertados de propósito: o painel do meio tem só
    // ~260px de altura para greet + capa + controles, e cada pixel aqui sai da
    // capa (medido: 20 -> 14 e 12 -> 8 devolvem ~20px de capa).
    anchors.fill: parent
    anchors.margins: 14
    spacing: 8

    // ---- topo: saudação (esquerda) e botões de app (canto direito) ----
    Item {
      id: topBand
      Layout.fillWidth: true
      Layout.preferredHeight: 48

      DashControlExtras {
        anchors.fill: parent
      }
    }

    // ---- meio: capa do player ----
    Item {
      id: coverBand
      Layout.fillWidth: true
      Layout.fillHeight: true

      DashPlayerCover {
        id: cover
        anchors.centerIn: parent
      }
    }

    // ---- base: controles de play ----
    Item {
      id: baseBand
      Layout.fillWidth: true
      Layout.preferredHeight: 54

      DashPlayButtons {
        anchors.centerIn: parent
      }
    }
  }
}
