import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Uma categoria de raio (Shell/Botões/Inputs/Janelas) com um slider - usada
// por RadiusCustomizer.qml. "value"/"maxValue" são em pixels; o Slider por
// baixo só entende 0..1, então a conversão pra pixel acontece aqui.
RowLayout {
    id: root

    property string label
    property int value // px
    property int maxValue: 32

    signal moved(int value)

    spacing: Colors.spacing

    Text {
        text: root.label
        color: Colors.foreground
        font.pixelSize: 12
        font.family: Colors.fontFamily
        Layout.preferredWidth: 90
    }

    Slider {
        Layout.fillWidth: true
        value: root.maxValue > 0 ? root.value / root.maxValue : 0
        onMoved: (v) => root.moved(Math.round(v * root.maxValue))
    }

    Text {
        text: root.value + "px"
        color: Colors.foregroundMuted
        font.pixelSize: 11
        font.family: Colors.fontFamily
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
