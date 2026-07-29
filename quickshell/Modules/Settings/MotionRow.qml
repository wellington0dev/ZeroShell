import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Uma categoria de duração (Rápida/Normal/Lenta) com um slider - usada por
// MotionCustomizer.qml. "value"/"maxValue" são em milissegundos; o Slider por
// baixo só entende 0..1, mesma conversão do RadiusRow.qml.
RowLayout {
    id: root

    property string label
    property int value // ms
    property int maxValue: 600

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
        text: root.value + "ms"
        color: Colors.foregroundMuted
        font.pixelSize: 11
        font.family: Colors.fontFamily
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
