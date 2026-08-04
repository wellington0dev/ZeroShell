import QtQuick
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets
import qs.State

// Botão de Bluetooth da sidebar - mesmo espírito de WifiButton.qml: ícone
// muda com o estado (adaptador desligado/sem adaptador vs ligado) e o
// clique é um toggle das Configurações na aba Bluetooth.
//
// Só 2 desenhos (ligado/desligado), sem tier por "força de sinal" tipo o
// Wi-Fi - Bluetooth não tem um equivalente natural a isso (a lista de
// dispositivos já mostra conectado/pareado individualmente dentro da aba).
IconButton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool onBluetoothPanel: Visibility.settingsOpen && Visibility.settingsCategory === "bluetooth"

    icon: (root.adapter && root.adapter.enabled) ? "bluetooth" : "bluetooth-off"
    active: root.onBluetoothPanel
    size: 32

    onClicked: {
        if (root.onBluetoothPanel) {
            Visibility.settingsOpen = false
        } else {
            Visibility.settingsCategory = "bluetooth"
            Visibility.settingsOpen = true
        }
    }
}
