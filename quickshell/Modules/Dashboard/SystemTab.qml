import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.Theme

// Aba "Sistema" do Dashboard: grade "bento" assimétrica em vez de 4 cards
// idênticos - bateria vira um "tanque" que enche feito líquido (à
// esquerda), CPU ganha um card "hero" largo e mais chamativo (no meio), e
// RAM/armazenamento ficam empilhados numa coluna estreita (à direita).
// Referência: github.com/caelestia-dots/shell (BatteryTank.qml, HeroCard.qml).
//
// Raiz usa anchors em vez de RowLayout pra dividir as 3 colunas: um
// RowLayout aqui não distribuía o espaço extra (Layout.fillWidth) direito
// pro card do meio - mesmo problema já visto em HomeTab.qml, mesma
// solução (larguras fixas via anchors, sem depender do fillWidth).
Item {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool batteryReady: battery && battery.ready && battery.isLaptopBattery
    readonly property int batteryPercent: batteryReady ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: batteryReady && battery.state === UPowerDeviceState.Charging

    readonly property string batteryIcon: charging
        ? "battery-charging"
        : batteryPercent >= 80 ? "battery-full"
        : batteryPercent >= 55 ? "battery-high"
        : batteryPercent >= 30 ? "battery-medium"
        : batteryPercent >= 15 ? "battery-low"
        : "battery-empty"

    readonly property int gap: 14
    readonly property int tankWidth: 92
    readonly property int sideColumnWidth: 168

    TankMeter {
        id: tank

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.batteryReady ? root.tankWidth : 0
        visible: root.batteryReady

        icon: root.batteryIcon
        label: root.charging ? "Carregando" : "Bateria"
        percent: root.batteryPercent
        fillColor: (root.batteryPercent <= 20 && !root.charging) ? Colors.danger : Colors.accent
    }

    ColumnLayout {
        id: sideColumn

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sideColumnWidth
        spacing: root.gap

        RingMeter {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: "ram"
            label: "Memória"
            percent: SystemStats.ramPercent
            ringColor: percent >= 85 ? Colors.danger : Colors.accentAlt
        }

        RingMeter {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: "disk"
            label: "Armazenamento"
            percent: SystemStats.storagePercent
            ringColor: percent >= 90 ? Colors.danger : Colors.accent
        }
    }

    HeroMeter {
        anchors.left: root.batteryReady ? tank.right : parent.left
        anchors.leftMargin: root.batteryReady ? root.gap : 0
        anchors.right: sideColumn.left
        anchors.rightMargin: root.gap
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        icon: "cpu"
        label: "CPU"
        sublabel: "Uso do processador"
        percent: SystemStats.cpuPercent
        ringColor: percent >= 85 ? Colors.danger : Colors.accent
    }
}
