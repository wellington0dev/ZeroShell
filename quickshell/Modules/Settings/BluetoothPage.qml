import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets
import qs.State

Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    property var selectedDevice: null

    // Conectado primeiro, depois pareado, depois o resto (recém-achado
    // durante o scan) - dentro de cada grupo, ordem alfabética. Sem isso a
    // lista vinha na ordem de descoberta do backend, então um device já
    // pareado podia sumir no meio de fones/mouses de vizinhos aparecendo
    // durante o scan.
    readonly property var sortedDevices: root.adapter
        ? [...root.adapter.devices.values].sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return a.name.localeCompare(b.name)
        })
        : []

    function syncDiscovery() {
        if (root.adapter && root.adapter.enabled) root.adapter.discovering = true
    }

    onAdapterChanged: syncDiscovery()
    Component.onCompleted: syncDiscovery()
    Component.onDestruction: if (root.adapter && root.adapter.enabled) root.adapter.discovering = false

    Connections {
        target: root.adapter
        function onEnabledChanged() { root.syncDiscovery() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Bluetooth"
                color: Styles.foreground
                font.pixelSize: 16
                font.family: Styles.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Switch {
                // "QuickSettings.bluetoothEnabled" (não "root.adapter.enabled"
                // direto) - é a preferência PERSISTIDA (ver State/
                // QuickSettings.qml pro porquê: este bluez não liga o
                // adaptador sozinho no boot). Mexer só no adaptador aqui
                // desincronizaria do que fica salvo, e o próximo restart do
                // shell reaplicaria o valor salvo antigo por cima.
                checked: QuickSettings.bluetoothEnabled
                onToggled: QuickSettings.setBluetoothEnabled(!QuickSettings.bluetoothEnabled)
            }
        }

        Text {
            visible: !root.adapter
            text: "Nenhum adaptador Bluetooth encontrado"
            color: Styles.foregroundMuted
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.adapter && root.adapter.enabled
            spacing: Styles.spacing

            Text {
                text: "Visível para outros dispositivos"
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                Layout.fillWidth: true
            }

            Switch {
                checked: root.adapter ? root.adapter.discoverable : false
                onToggled: if (root.adapter) root.adapter.discoverable = !root.adapter.discoverable
            }
        }

        Text {
            visible: root.adapter && root.adapter.enabled && root.sortedDevices.length === 0
            text: "Procurando dispositivos…"
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
        }

        ListView {
            visible: root.adapter && root.adapter.enabled && root.sortedDevices.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Styles.spacing
            clip: true
            model: root.sortedDevices

            delegate: DeviceRow {
                width: ListView.view.width
                device: modelData
                selected: root.selectedDevice === modelData
                onClicked: root.selectedDevice = (root.selectedDevice === modelData ? null : modelData)
            }
        }

        // Keeps the header pinned to the top when the list above is hidden
        // (no adapter, adapter disabled, or still scanning) instead of the
        // column re-centering.
        Item {
            visible: !(root.adapter && root.adapter.enabled && root.sortedDevices.length > 0)
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
