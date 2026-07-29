import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Duração das animações (Rápida/Normal/Lenta) - usada pela aba "Aparência"
// das Configurações. Puro CSS/QML (Motion.durationFast/Normal/Slow,
// Theme/Motion.qml) - muda na hora, sem precisar de script bash nem reload
// do Hyprland (diferente do raio de "Janelas" em RadiusCustomizer.qml).
ColumnLayout {
    id: root

    spacing: Colors.spacing

    Text {
        text: "Controla a velocidade dos painéis deslizando, pop-ins e outras transições do shell inteiro."
        color: Colors.foregroundMuted
        font.pixelSize: 11
        font.family: Colors.fontFamily
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    MotionRow {
        Layout.fillWidth: true
        label: "Rápida"
        value: Motion.durationFast
        maxValue: 400
        onMoved: (v) => Motion.setDuration("fast", v)
    }

    MotionRow {
        Layout.fillWidth: true
        label: "Normal"
        value: Motion.durationNormal
        maxValue: 600
        onMoved: (v) => Motion.setDuration("normal", v)
    }

    MotionRow {
        Layout.fillWidth: true
        label: "Lenta"
        value: Motion.durationSlow
        maxValue: 800
        onMoved: (v) => Motion.setDuration("slow", v)
    }

    Item { Layout.fillHeight: true }
}
