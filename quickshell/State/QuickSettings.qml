pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Toggles rápidos do shell (aba "Ajustes" do Dashboard - QuickSettingsTab.qml):
// notificações, "manter acordado" e Bluetooth. Cada um é lido por um módulo
// diferente que nem se conhece diretamente (NotificationPopups.qml,
// LockScreen.qml, Sidebar.qml, BluetoothPage.qml) - esse singleton é o ponto
// de encontro, mesmo raciocínio do State/Visibility.qml.
Singleton {
    id: root

    // Persistido (JSON) - "mudo" é uma preferência que devia sobreviver a um
    // reinício do quickshell, senão o usuário desligaria de novo toda vez.
    readonly property bool notificationsEnabled: adapter.notificationsEnabled

    function setNotificationsEnabled(value) {
        adapter.notificationsEnabled = value
        settingsFile.writeAdapter()
    }

    // Bluetooth ligado/desligado - PERSISTIDO, ao contrário de "keepAwake"
    // abaixo. Este sistema não tem AutoEnable ligado em
    // /etc/bluetooth/main.conf, então o bluez sempre sobe com o adaptador
    // DESLIGADO a cada boot/reinício do bluetoothd - sem guardar a
    // preferência aqui e reaplicá-la, o usuário precisaria ligar o
    // Bluetooth de novo toda vez que o shell (re)iniciasse, mesmo já tendo
    // ligado antes. BluetoothPage.qml/QuickSettingsTab.qml chamam
    // `setBluetoothEnabled` em vez de mexer em `Bluetooth.defaultAdapter.
    // enabled` direto, senão a preferência salva e o adaptador ao vivo
    // divergiam (ligava aqui, desligava lá, e o próximo restart "voltava"
    // pro estado errado).
    readonly property bool bluetoothEnabled: adapter.bluetoothEnabled

    function setBluetoothEnabled(value) {
        adapter.bluetoothEnabled = value
        adapter.bluetoothEnabledSet = true
        settingsFile.writeAdapter()
        _applyBluetooth()
    }

    // Só aplica UMA VEZ por vida do singleton (ver "_appliedOnce" abaixo) -
    // de propósito NÃO fica reagindo a toda mudança do adaptador depois
    // disso. Ficar vigiando e reescrevendo ".enabled" reativamente (a
    // primeira versão deste fix fazia isso via onDefaultAdapterChanged) é
    // arriscado: qualquer motivo pro Quickshell recriar o objeto do
    // adaptador no meio de uma conexão/pareamento em andamento reaplicaria
    // o valor salvo por cima bem naquele momento, derrubando a conexão. O
    // objetivo aqui é só "lembrar entre reinícios do shell", não "manter o
    // adaptador nesse estado o tempo todo" - uma aplicação única no boot já
    // resolve isso sem esse risco.
    property bool _appliedOnce: false

    function _applyBluetooth() {
        // "settingsFile.loaded" é o que faltava antes: FileView carrega o
        // JSON do disco de forma ASSÍNCRONA - Component.onCompleted roda na
        // hora, antes do arquivo terminar de carregar, então "adapter.*"
        // ainda estava nos valores padrão de compilação (false/false) toda
        // vez que este singleton recarregava (ex.: a cada edição deste
        // próprio arquivo, que sendo "pragma Singleton" recria o módulo
        // inteiro) - lia "bluetoothEnabledSet=false" MESMO quando já tinha
        // sido salvo true antes, achava que era a primeira vez, e
        // "adotava" o estado atual... só que se o adaptador tivesse acabado
        // de mudar por outro motivo, ou a ordem de eventos variasse, podia
        // acabar forçando desligado. Sem esperar "loaded", essa função
        // simplesmente não tinha como saber se já leu o valor de verdade.
        if (root._appliedOnce || !Bluetooth.defaultAdapter || !settingsFile.loaded) return
        root._appliedOnce = true
        if (!adapter.bluetoothEnabledSet) {
            // Primeira vez que este código roda pra este usuário (upgrade
            // de uma versão sem esta preferência - "bluetoothEnabledSet"
            // não existe ainda no JSON antigo, então lê como false) - ADOTA
            // o estado atual do adaptador em vez de forçar o default
            // arbitrário (false) por cima. Sem isto, uma conexão Bluetooth
            // já ativa seria derrubada de surpresa bem no primeiro reload
            // depois deste fix, só porque a preferência nunca tinha sido
            // salva antes.
            adapter.bluetoothEnabled = Bluetooth.defaultAdapter.enabled
            adapter.bluetoothEnabledSet = true
            settingsFile.writeAdapter()
            return
        }
        if (Bluetooth.defaultAdapter.enabled !== root.bluetoothEnabled) {
            Bluetooth.defaultAdapter.enabled = root.bluetoothEnabled
        }
    }

    // O adaptador pode não estar pronto ainda quando o shell sobe (bluetoothd
    // inicializando em paralelo) - "_appliedOnce" garante que, mesmo
    // escutando aqui até ele aparecer, só mexemos nele UMA vez de verdade.
    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root._applyBluetooth() }
    }

    Component.onCompleted: root._applyBluetooth()

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/quick-settings.json"
        // O outro lado da corrida: quando o ARQUIVO termina de carregar
        // (pode ser DEPOIS do Component.onCompleted acima, ou depois do
        // adaptador Bluetooth aparecer) - tenta aplicar de novo nesse
        // momento. "_appliedOnce" evita fazer isso mais de uma vez.
        onLoaded: root._applyBluetooth()

        JsonAdapter {
            id: adapter
            property bool notificationsEnabled: true
            property bool bluetoothEnabled: false
            // false pra qualquer JSON salvo ANTES deste fix existir - é
            // esse "nunca foi definido" que aciona a adoção do estado atual
            // em vez de forçar o default (ver _applyBluetooth()).
            property bool bluetoothEnabledSet: false
        }
    }

    // "Manter acordado" NÃO é persistido de propósito - é um estado
    // temporário ("tô assistindo algo agora"), não uma preferência
    // duradoura. Persistir isso faria a tela nunca mais travar sozinha se o
    // usuário esquecesse de desligar antes de fechar a sessão.
    property bool keepAwake: false

    function setKeepAwake(value) {
        root.keepAwake = value
    }
}
