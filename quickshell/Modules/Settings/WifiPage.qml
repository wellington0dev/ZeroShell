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

    // Conectada primeiro, depois por força de sinal (maior primeiro) - sem
    // isso a lista vinha na ordem que o backend descobriu cada rede
    // (basicamente aleatória), então a rede que você já está usando podia
    // aparecer no meio/fim da lista.
    readonly property var sortedNetworks: root.device
        ? [...root.device.networks.values].sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return b.signalStrength - a.signalStrength
        })
        : []

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

        Text {
            visible: root.device && Networking.wifiEnabled && root.sortedNetworks.length === 0
            text: "Procurando redes…"
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
        }

        ListView {
            visible: root.device && Networking.wifiEnabled && root.sortedNetworks.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Styles.spacing
            clip: true
            model: root.sortedNetworks

            delegate: NetworkRow {
                width: ListView.view.width
                network: modelData
                selected: root.selectedNetwork === modelData
                onClicked: root.selectedNetwork = (root.selectedNetwork === modelData ? null : modelData)
            }
        }

        // Keeps the header pinned to the top when the list above is hidden
        // (no device, Wi-Fi disabled, or still scanning) instead of the
        // column re-centering.
        Item {
            visible: !(root.device && Networking.wifiEnabled && root.sortedNetworks.length > 0)
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
