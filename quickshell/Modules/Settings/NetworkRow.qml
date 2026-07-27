import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    property WifiNetwork network
    property bool selected: false

    signal clicked()

    property string error: ""
    property string password: ""

    spacing: Colors.spacing / 2

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            root.error = reason === ConnectionFailReason.NoSecrets
                ? "Senha incorreta"
                : "Não foi possível conectar"
        }
    }

    onSelectedChanged: if (!selected) { root.error = ""; root.password = "" }

    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacing

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.network.connected ? Colors.success : "transparent"
            border.color: Colors.border
            border.width: root.network.connected ? 0 : 1
        }

        Text {
            text: root.network.name
            color: Colors.foreground
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: root.network.security !== WifiSecurityType.Open
            text: "🔒"
            font.pixelSize: 11
        }

        Text {
            text: Math.round(root.network.signalStrength * 100) + "%"
            color: Colors.foregroundMuted
            font.pixelSize: 11
        }

        TapHandler { onTapped: root.clicked() }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        visible: root.selected
        spacing: Colors.spacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacing
            visible: root.network.connected

            Text {
                text: "Conectado a esta rede"
                color: Colors.foregroundMuted
                font.pixelSize: 11
                Layout.fillWidth: true
            }

            Button {
                text: "Desconectar"
                primary: false
                onClicked: root.network.disconnect()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacing
            visible: !root.network.connected && root.network.known

            Text {
                text: "Rede salva"
                color: Colors.foregroundMuted
                font.pixelSize: 11
                Layout.fillWidth: true
            }

            Button {
                text: "Conectar"
                onClicked: root.network.connect()
            }

            Button {
                text: "Esquecer"
                primary: false
                onClicked: root.network.forget()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacing / 2
            visible: !root.network.connected && !root.network.known

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacing

                PasswordField {
                    Layout.fillWidth: true
                    visible: root.network.security !== WifiSecurityType.Open
                    placeholder: "Senha"
                    onTextChanged: root.password = text
                    onAccepted: root.network.connectWithPsk(root.password)
                }

                Button {
                    text: "Conectar"
                    onClicked: root.network.security === WifiSecurityType.Open
                        ? root.network.connect()
                        : root.network.connectWithPsk(root.password)
                }
            }

            Text {
                visible: root.error.length > 0
                text: root.error
                color: Colors.danger
                font.pixelSize: 11
            }
        }
    }
}
