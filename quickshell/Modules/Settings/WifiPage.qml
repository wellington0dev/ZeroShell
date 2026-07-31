import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.Theme
import qs.Widgets

Item {
    id: root

    readonly property WifiDevice device: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    property var selectedNetwork: null

    Component.onCompleted: if (device) device.scannerEnabled = true
    onDeviceChanged: if (device) device.scannerEnabled = true
    Component.onDestruction: if (device) device.scannerEnabled = false

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Wi-Fi"
                color: Styles.foreground
                font.pixelSize: 16
                font.family: Styles.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Switch {
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Text {
            visible: !root.device
            text: "Nenhum adaptador Wi-Fi encontrado"
            color: Styles.foregroundMuted
        }

        ListView {
            visible: root.device && Networking.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Styles.spacing
            clip: true
            model: root.device ? root.device.networks.values : []

            delegate: NetworkRow {
                width: ListView.view.width
                network: modelData
                selected: root.selectedNetwork === modelData
                onClicked: root.selectedNetwork = (root.selectedNetwork === modelData ? null : modelData)
            }
        }

        // Keeps the header pinned to the top when the list above is hidden
        // (no device, or Wi-Fi disabled) instead of the column re-centering.
        Item {
            visible: !(root.device && Networking.wifiEnabled)
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
