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
// "DashboardState" (dono único do estado + IpcHandler "dashboard") mora em
// "qs.Modules.Dashboard", e NÃO em "qs.State" - o DashboardWindow antigo só
// funcionava porque está nesse mesmo módulo.
import qs.Modules.Dashboard
import qs.Modules.Sidebar.RumdaConfig
import qs.Modules.Dashboard.RumdaDashboard

Scope {
  id: dashboardScope
  property int closeDuration: Config.dashAnimDuration
  readonly property int dashWidth: Config.dashboardWidth
  readonly property int dashHeight: Config.dashboardHeight

  Timer {
    id: closeTimer
    interval: dashboardScope.closeDuration
    repeat: false
    // Só a animação: o estado já foi virado por quem chamou closeDashboard.
    onTriggered: {
      dashboardBGRect.visible = false;
      dashboardBGRect.animating = false;
    }
  }

  // O estado NÃO mora aqui: mora no DashboardState (único dono, com o
  // IpcHandler "dashboard" e o atalho Super+TAB). Estas funções cuidam só da
  // animação; quem muda o estado é o DashboardState, e o "visible" do
  // WlrLayershell segue ele - assim atalho, IPC e clique abrem igual.
  function openDashboard() {
    dashboardBGRect.animating = false;
    dashboardBGRect.visible = true;
    dashboardBGRect.y = dashboard.screenH;
    Qt.callLater(() => {
      dashboardBGRect.animating = true;
      dashboardBGRect.y = (dashboard.screenH - dashboardScope.dashHeight) * 0.5;
    });
  }

  function closeDashboard() {
    DashboardState.setOpen(false);
    dashboardBGRect.animating = true;
    dashboardBGRect.y = dashboard.screenH;
    closeTimer.start();
  }

  // Quando o DashboardState fecha por fora (IPC "close", atalho de novo, o
  // próprio IpcHandler toggle), a animação de saída precisa rodar também.
  Connections {
    target: DashboardState
    function onOpenChanged() {
      if (DashboardState.open) dashboardScope.openDashboard();
      else dashboardScope.closeDashboard();
    }
  }

  WlrLayershell {
    id: dashboard
    readonly property int screenW: Screen.width
    readonly property int screenH: Screen.height
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    // Camada "Top", e não "Overlay" como no Rumda: o painel de captura
    // (Modules/Capture/CaptureMenu.qml), o Launcher, a PowerMenu e as
    // Configurações são todos PanelWindow = "Overlay". Com o dashboard também
    // no Overlay, quem fosse mapeado depois ficava ATRÁS dele - que era
    // exatamente o caso do menu de captura: ele abria debaixo do card, os
    // botões "Regra/Capturar" não recebiam clique e o print saía sem o
    // dashboard. No "Top" o dashboard continua acima da janela comum, com
    // foco de teclado exclusivo, e qualquer painel do shell abre por cima
    // dele.
    layer: WlrLayer.Top
    // exclusiveZone: -1
    // Quem manda no "visible" é o DashboardState (único dono do estado), e não
    // a animação: se fosse a animação, fechar pelo atalho sumiria com o card
    // mas a camada continuaria mapeada.
    visible: DashboardState.open
    color: "transparent"
    keyboardFocus: WlrKeyboardFocus.Exclusive

    FocusScope {
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          dashboardScope.closeDashboard();
          event.accepted = true;
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: dashboardScope.closeDashboard()

        // Sem DropShadow: o card é uma superfície layer-shell (WlrLayershell),
        // e a sombra aqui ficava uma mancha escura em volta do card em vez de
        // profundidade. Todos os painéis do shell (PowerMenu, Configurações,
        // Volume) usam borda de 1px na cor do tema, sem sombra - é o mesmo
        // que o card usa agora.

        Rectangle {
          id: dashboardBGRect
          width: dashboardScope.dashWidth
          height: dashboardScope.dashHeight
          anchors.horizontalCenter: parent.horizontalCenter
          y: 0
          visible: false

          color: Colors.dashBGColor
          radius: Config.dashRadius
          // Borda do card: 1px na cor de borda do tema (Styles.border), como
          // os outros painéis do shell. Antes o contorno era da "wrapper"
          // interna (Config.dashBorderWidth = 3px), 10px mais pra dentro - e
          // o card em si não tinha borda nenhuma.
          border.width: 1
          border.color: Styles.border

          MouseArea {
            anchors.fill: parent
          }

          property bool animating: false

          Behavior on y {
            enabled: dashboardBGRect.animating
            NumberAnimation {
              duration: dashboardScope.closeDuration
              easing.type: Easing.InOutCubic
            }
          }

          Rectangle {
            id: dashInnerWrapper
            anchors.fill: parent
            anchors.margins: Config.dashInnerPadding
            radius: Config.dashRadius
            color: Colors.dashBGColor
            // Borda fica no container principal (o card) - aqui seria um
            // segundo contorno, 10px mais pra dentro.
            border.width: 0

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Config.dashInnerPadding
              spacing: Config.dashInnerPadding

              RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * Config.dashTopRowRatio
                spacing: Config.dashInnerPadding

                ProfileAndPower {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                }

                DashBoardControls {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                }

                DashBrightnessControl {
                  Layout.fillHeight: true
                  Layout.minimumWidth: 65
                  Layout.maximumWidth: 80
                }
              }

              ContribGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * (1.0 - Config.dashTopRowRatio)
              }
            }
          }
        }
      }
    }
  }
}
