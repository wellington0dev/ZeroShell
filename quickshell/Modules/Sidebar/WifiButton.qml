import QtQuick
import Quickshell.Networking
import qs.Theme
import qs.Widgets
import qs.State

// Botão de Wi-Fi da sidebar - o ícone muda com o estado real da rede (rádio
// desligado/sem adaptador, ligado mas sem conexão, ou conectado com um
// desenho por faixa de força de sinal - mesma ideia dos tiers de
// Battery.qml, só que pra "signalStrength" em vez de percentual de carga).
//
// Clique é um toggle: abre as Configurações já na aba Wi-Fi se não
// estiverem nela, ou fecha se já estiver com a aba Wi-Fi aberta (mesmo
// espírito do toggle simples de "settingsComp" em Sidebar.qml, só que
// também fixa a categoria).
IconButton {
    id: root

    readonly property WifiDevice device: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    readonly property WifiNetwork connectedNetwork: {
        if (!root.device) return null
        for (const n of root.device.networks.values) {
            if (n.connected) return n
        }
        return null
    }

    readonly property bool onWifiPanel: Visibility.settingsOpen && Visibility.settingsCategory === "wifi"

    icon: {
        if (!Networking.wifiEnabled || !root.device || !root.connectedNetwork) return "wifi-off"
        // "signalStrength" vem como fração 0..1, não 0..100 (mesma pegadinha
        // de "device.percentage" em Battery.qml - confirmado em NetworkRow.qml,
        // que faz "signalStrength * 100" pra mostrar o "%").
        const s = root.connectedNetwork.signalStrength
        if (s >= 0.7) return "wifi"
        if (s >= 0.35) return "wifi-medium"
        return "wifi-low"
    }

    active: root.onWifiPanel

    onClicked: {
        if (root.onWifiPanel) {
            Visibility.settingsOpen = false
        } else {
            Visibility.settingsCategory = "wifi"
            Visibility.settingsOpen = true
        }
    }
}
