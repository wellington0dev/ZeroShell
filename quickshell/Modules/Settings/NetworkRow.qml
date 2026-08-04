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

    spacing: Styles.spacing / 2

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
        spacing: Styles.spacing

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.network.connected ? Styles.success : "transparent"
            border.color: Styles.border
            border.width: root.network.connected ? 0 : 1
        }

        Text {
            text: root.network.name
            color: Styles.foreground
            font.pixelSize: 13
            font.family: Styles.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: root.network.security !== WifiSecurityType.Open
            text: "🔒"
            font.pixelSize: 11
            font.family: Styles.fontFamily
        }

        Text {
            text: Math.round(root.network.signalStrength * 100) + "%"
            color: Styles.foregroundMuted
            font.pixelSize: 11
            font.family: Styles.fontFamily
        }

        TapHandler { onTapped: root.clicked() }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        visible: root.selected
        spacing: Styles.spacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing
            visible: root.network.connected

            Text {
                text: "Conectado a esta rede"
                color: Styles.foregroundMuted
                font.pixelSize: 11
                font.family: Styles.fontFamily
                Layout.fillWidth: true
            }

            Button {
                text: "Desconectar"
                primary: false
                onClicked: root.network.disconnect()
            }

            Button {
                text: "Esquecer"
                primary: false
                onClicked: root.network.forget()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing
            visible: !root.network.connected && root.network.known

            Text {
                text: "Rede salva"
                color: Styles.foregroundMuted
                font.pixelSize: 11
                font.family: Styles.fontFamily
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
            spacing: Styles.spacing / 2
            visible: !root.network.connected && !root.network.known

            RowLayout {
                Layout.fillWidth: true
                spacing: Styles.spacing

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
                color: Styles.danger
                font.pixelSize: 11
                font.family: Styles.fontFamily
            }
        }
    }
}
