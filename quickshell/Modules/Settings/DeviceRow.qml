import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    property BluetoothDevice device
    property bool selected: false

    signal clicked()

    spacing: Colors.spacing / 2

    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacing

        Icon {
            size: 20
            icon: "bluetooth"
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.device.name
                color: Colors.foreground
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.device.state === BluetoothDeviceState.Connected ? "Conectado"
                    : root.device.state === BluetoothDeviceState.Connecting ? "Conectando…"
                    : root.device.paired ? "Pareado" : ""
                color: Colors.foregroundMuted
                font.pixelSize: 11
                visible: text.length > 0
            }
        }

        Text {
            visible: root.device.batteryAvailable
            text: Math.round(root.device.battery * 100) + "%"
            color: Colors.foregroundMuted
            font.pixelSize: 11
        }

        TapHandler { onTapped: root.clicked() }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        visible: root.selected
        spacing: Colors.spacing

        Button {
            text: root.device.connected ? "Desconectar" : "Conectar"
            primary: !root.device.connected
            enabled: root.device.paired
            onClicked: root.device.connected = !root.device.connected
        }

        Button {
            text: root.device.paired ? "Parear novamente" : "Parear"
            primary: false
            onClicked: root.device.pair()
        }

        Button {
            visible: root.device.bonded
            text: "Esquecer"
            primary: false
            onClicked: root.device.forget()
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 4

            Text {
                text: "Confiar"
                color: Colors.foregroundMuted
                font.pixelSize: 11
            }

            Switch {
                checked: root.device.trusted
                onToggled: root.device.trusted = !root.device.trusted
            }
        }
    }
}
