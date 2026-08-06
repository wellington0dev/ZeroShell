import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets

// Uma linha de dispositivo pareável (BluetoothPage.qml). Conectar/parear
// via Bluetooth.Device não devolve erro nenhum pra QML (a API não expõe
// "por que falhou") - só um bool ("connected"/"paired") e um "state" sem
// estado de falha próprio (só Disconnected/Connected/Disconnecting/
// Connecting). Então o único jeito de perceber falha aqui é por AUSÊNCIA de
// sucesso: disparamos a tentativa, ligamos um timeout, e se o estado voltar
// pra "parado" sem nunca ter chegado no "conectado"/"pareado" de verdade, é
// falha - sem isso o clique em "Conectar" era literalmente mudo quando não
// funcionava (nem erro, nem nada, o usuário só ficava sem saber o que
// aconteceu).
ColumnLayout {
    id: root

    property BluetoothDevice device
    property bool selected: false

    property bool connectAttempting: false
    property bool connectFailed: false
    property bool pairAttempting: false
    property bool pairFailed: false

    signal clicked()

    spacing: Styles.spacing / 2

    function tryConnect() {
        root.connectFailed = false
        root.connectAttempting = true
        connectTimeout.restart()
        root.device.connected = true
    }

    function disconnectDevice() {
        connectTimeout.stop()
        root.connectAttempting = false
        root.connectFailed = false
        root.device.connected = false
    }

    function tryPair() {
        root.pairFailed = false
        root.pairAttempting = true
        // Pareamento de verdade às vezes espera confirmação manual no OUTRO
        // aparelho (aceitar no fone, digitar um PIN) - timeout bem mais
        // folgado que o de conectar, pra não gritar "falha" enquanto o
        // usuário ainda está confirmando do outro lado.
        pairTimeout.restart()
        root.device.pair()
    }

    Timer {
        id: connectTimeout
        interval: 12000
        onTriggered: {
            root.connectAttempting = false
            root.connectFailed = true
        }
    }

    Timer {
        id: pairTimeout
        interval: 20000
        onTriggered: {
            root.pairAttempting = false
            root.pairFailed = true
        }
    }

    Connections {
        target: root.device

        function onStateChanged() {
            if (!root.connectAttempting) return
            if (root.device.state === BluetoothDeviceState.Connected) {
                connectTimeout.stop()
                root.connectAttempting = false
                root.connectFailed = false
            } else if (root.device.state === BluetoothDeviceState.Disconnected) {
                // Voltou pra "desconectado" no meio de uma tentativa nossa
                // (não terminou em "conectado") = falhou.
                connectTimeout.stop()
                root.connectAttempting = false
                root.connectFailed = true
            }
        }

        function onPairingChanged() {
            if (!root.pairAttempting || root.device.pairing) return
            // "pairing" voltou a false - terminou (sucesso ou falha).
            // "paired" é o veredito.
            pairTimeout.stop()
            root.pairAttempting = false
            root.pairFailed = !root.device.paired
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Styles.spacing

        Icon {
            size: 20
            icon: "bluetooth"
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.device.name
                color: Styles.foreground
                font.pixelSize: 13
                font.family: Styles.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.connectFailed ? "Falha ao conectar - tenta de novo?"
                    : root.pairFailed ? "Falha ao parear - tenta de novo?"
                    : (root.device.state === BluetoothDeviceState.Connected) ? "Conectado"
                    : (root.device.state === BluetoothDeviceState.Connecting || root.connectAttempting) ? "Conectando…"
                    : root.pairAttempting ? "Pareando… (confira o outro aparelho)"
                    : root.device.paired ? "Pareado" : ""
                color: (root.connectFailed || root.pairFailed) ? Styles.danger : Styles.foregroundMuted
                font.pixelSize: 11
                font.family: Styles.fontFamily
                visible: text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }

        Text {
            visible: root.device.batteryAvailable
            text: Math.round(root.device.battery * 100) + "%"
            color: Styles.foregroundMuted
            font.pixelSize: 11
            font.family: Styles.fontFamily
        }

        TapHandler { onTapped: root.clicked() }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        visible: root.selected
        spacing: Styles.spacing

        Button {
            text: root.device.connected ? "Desconectar" : (root.connectAttempting ? "Conectando…" : "Conectar")
            primary: !root.device.connected
            enabled: root.device.paired && !root.connectAttempting
            onClicked: root.device.connected ? root.disconnectDevice() : root.tryConnect()
        }

        Button {
            text: root.pairAttempting ? "Pareando…" : (root.device.paired ? "Parear novamente" : "Parear")
            primary: false
            enabled: !root.pairAttempting
            onClicked: root.tryPair()
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
                color: Styles.foregroundMuted
                font.pixelSize: 11
                font.family: Styles.fontFamily
            }

            Switch {
                checked: root.device.trusted
                onToggled: root.device.trusted = !root.device.trusted
            }
        }
    }
}
