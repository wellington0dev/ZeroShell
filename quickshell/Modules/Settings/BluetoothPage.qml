import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets

Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    property var selectedDevice: null

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
                checked: root.adapter ? root.adapter.enabled : false
                onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        }

        Text {
            visible: !root.adapter
            text: "Nenhum adaptador Bluetooth encontrado"
            color: Styles.foregroundMuted
        }

        ListView {
            visible: root.adapter && root.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Styles.spacing
            clip: true
            model: root.adapter ? root.adapter.devices.values : []

            delegate: DeviceRow {
                width: ListView.view.width
                device: modelData
                selected: root.selectedDevice === modelData
                onClicked: root.selectedDevice = (root.selectedDevice === modelData ? null : modelData)
            }
        }

        // Keeps the header pinned to the top when the list above is hidden
        // (no adapter, or adapter disabled) instead of the column re-centering.
        Item {
            visible: !(root.adapter && root.adapter.enabled)
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
