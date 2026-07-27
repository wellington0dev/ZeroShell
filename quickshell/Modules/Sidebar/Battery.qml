import QtQuick
import Quickshell.Services.UPower
import qs.Theme
import qs.Widgets

// Ícone de bateria + porcentagem. O ícone muda de desenho conforme o nível
// (vazia/baixa/média/alta/cheia) e vira um raio quando carregando; a cor
// também muda pra vermelho quando a bateria está baixa e não carregando.
//
// "UPower.displayDevice" é o dispositivo "agregado" que o UPower expõe -
// mesmo em notebooks com mais de uma bateria, ele já resume tudo numa coisa
// só, então não precisamos escolher qual bateria mostrar.
Column {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool ready: device && device.ready && device.isLaptopBattery

    // Importante: "device.percentage" vem como fração 0..1, não 0..100 (apesar
    // do nome sugerir porcentagem já pronta) - descoberto testando ao vivo,
    // a doc do Quickshell não deixava isso claro.
    readonly property int percent: ready ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: ready && device.state === UPowerDeviceState.Charging
    readonly property color tint: !ready
        ? Colors.foregroundMuted
        : (charging ? Colors.accent : (percent <= 20 ? Colors.danger : Colors.foregroundMuted))

    readonly property string iconName: charging
        ? "battery-charging"
        : percent >= 80 ? "battery-full"
        : percent >= 55 ? "battery-high"
        : percent >= 30 ? "battery-medium"
        : percent >= 15 ? "battery-low"
        : "battery-empty"

    // Se o dispositivo não é uma bateria de notebook (ex.: rodando num
    // desktop sem bateria), o componente inteiro fica invisível.
    visible: ready
    spacing: 2

    Item {
        width: 32
        height: 16

        Icon {
            anchors.centerIn: parent
            icon: root.iconName
            size: 16
            tint: root.tint
        }
    }

    Text {
        width: 32
        horizontalAlignment: Text.AlignHCenter
        text: root.percent + "%"
        color: root.tint
        font.pixelSize: 11
    }
}
