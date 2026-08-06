import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.Theme
import qs.Widgets
import qs.State

// Aba "Ajustes" do Dashboard - toggles rápidos que não merecem abrir a
// janela inteira de Configurações. Grid "bento" 2x2 (QuickToggleTile.qml) em
// vez de linhas empilhadas - cada ajuste vira um cartão independente, mais
// fácil de escanear de relance do que uma lista comprida. Wi-Fi e Bluetooth
// também têm um botão de engrenagem no canto do próprio tile que leva pra
// aba cheia (WifiPage.qml/BluetoothPage.qml) pra quem precisa escolher
// rede/parear dispositivo - o Switch aqui só liga/desliga o rádio, não
// substitui a aba.
ColumnLayout {
    id: root

    readonly property WifiDevice wifiDevice: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    readonly property WifiNetwork wifiConnectedNetwork: {
        if (!root.wifiDevice) return null
        for (const n of root.wifiDevice.networks.values) {
            if (n.connected) return n
        }
        return null
    }

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled || !root.wifiDevice || !root.wifiConnectedNetwork) return "wifi-off"
        const s = root.wifiConnectedNetwork.signalStrength
        if (s >= 0.7) return "wifi"
        if (s >= 0.35) return "wifi-medium"
        return "wifi-low"
    }

    readonly property BluetoothAdapter btAdapter: Bluetooth.defaultAdapter

    readonly property var btConnectedDevices: root.btAdapter
        ? root.btAdapter.devices.values.filter(d => d.connected)
        : []

    spacing: Styles.spacing * 1.5

    RowLayout {
        Layout.fillWidth: true
        spacing: Styles.spacing

        Text {
            text: "Ajustes rápidos"
            color: Styles.foreground
            font.pixelSize: Styles.fontSizeLarge
            font.family: Styles.fontFamily
            font.bold: true
            Layout.fillWidth: true
        }

        // Mesmo botão/comportamento do ícone de engrenagem da Sidebar
        // (Modules/Sidebar/Sidebar.qml, "settingsComp") - replicado aqui
        // pra abrir a janela cheia de Configurações sem precisar fechar o
        // Dashboard primeiro pra alcançar a sidebar.
        IconButton {
            icon: "gear"
            active: Visibility.settingsOpen
            onClicked: Visibility.settingsOpen = !Visibility.settingsOpen
        }
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        rowSpacing: Styles.spacing
        columnSpacing: Styles.spacing

        QuickToggleTile {
            icon: root.wifiIcon
            title: "Wi-Fi"
            state: !Networking.wifiEnabled ? "Desligado"
                : root.wifiConnectedNetwork ? root.wifiConnectedNetwork.name
                : "Não conectado"
            checked: Networking.wifiEnabled
            showMore: true
            moreActive: Visibility.settingsOpen && Visibility.settingsCategory === "wifi"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onMoreClicked: {
                Visibility.settingsCategory = "wifi"
                Visibility.settingsOpen = true
            }
        }

        QuickToggleTile {
            icon: QuickSettings.bluetoothEnabled ? "bluetooth" : "bluetooth-off"
            title: "Bluetooth"
            state: !QuickSettings.bluetoothEnabled ? "Desligado"
                : root.btConnectedDevices.length > 0 ? root.btConnectedDevices.map(d => d.name).join(", ")
                : "Não conectado"
            // "QuickSettings.bluetoothEnabled" (não "root.btAdapter.enabled"
            // direto) - é a preferência PERSISTIDA (ver State/
            // QuickSettings.qml pro porquê: este bluez não liga o adaptador
            // sozinho no boot). Mexer só no adaptador aqui desincronizaria
            // do que fica salvo.
            checked: QuickSettings.bluetoothEnabled
            switchEnabled: !!root.btAdapter
            showMore: true
            moreActive: Visibility.settingsOpen && Visibility.settingsCategory === "bluetooth"
            onToggled: QuickSettings.setBluetoothEnabled(!QuickSettings.bluetoothEnabled)
            onMoreClicked: {
                Visibility.settingsCategory = "bluetooth"
                Visibility.settingsOpen = true
            }
        }

        QuickToggleTile {
            icon: QuickSettings.notificationsEnabled ? "bell" : "eye-off"
            title: "Notificações"
            state: "Desligado só esconde os popups - nada some do histórico."
            checked: QuickSettings.notificationsEnabled
            onToggled: QuickSettings.setNotificationsEnabled(!QuickSettings.notificationsEnabled)
        }

        QuickToggleTile {
            icon: "eye"
            title: "Manter acordado"
            state: "Impede a tela de travar/suspender sozinha enquanto ligado."
            checked: QuickSettings.keepAwake
            onToggled: QuickSettings.setKeepAwake(!QuickSettings.keepAwake)
        }
    }
}
