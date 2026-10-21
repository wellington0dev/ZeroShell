import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Modules.Dashboard
import qs.Modules.Sidebar.RumdaConfig

Rectangle {
  id: root


  Layout.alignment: Qt.AlignHCenter
  width: Styles.control
  height: 60
  radius: Config.innerBModulesRadius
  color: Colors.moduleBG
  border.width: 1
  border.color: Colors.borderColor

  // CPU/RAM vêm do singleton SystemStats (Modules/Dashboard/SystemStats.qml),
  // o mesmo que a barra vertical e a aba "Sistema" do Dashboard usam.
  //
  // Antes eram dois processos próprios do Rumda:
  //   top -bn1 | grep '%Cpu(s):' | awk '{print $2}' | sed 's/%us,//'
  //   free | grep Mem: | awk '{printf "%.0f", ($2-$7)/$2*100}'
  // NENHUM dos dois funciona nesta máquina: com o sistema em pt_BR o procps
  // imprime "%CPU(s):" (maiúsculas) e o free imprime "Mem.:", então os greps
  // não casavam - e os anéis ficavam sempre vazios.
  readonly property int cpuPercent: SystemStats.cpuPercent
  readonly property int ramPercent: SystemStats.ramPercent

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 2

    RadialIndicator {
      Layout.alignment: Qt.AlignHCenter
      percent: root.cpuPercent
      indicatorColor: Colors.accentColor
      backgroundColor: Styles.surfaceAlt
      size: 24
    }

    RadialIndicator {
      Layout.alignment: Qt.AlignHCenter
      percent: root.ramPercent
      indicatorColor: Colors.accent2Color
      backgroundColor: Styles.surfaceAlt
      size: 24
    }
  }
}
