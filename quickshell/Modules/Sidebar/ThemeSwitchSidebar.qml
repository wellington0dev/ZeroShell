import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// ThemeSwitchSidebar: toggle light/dark mode na sidebar.
// Usa o ícone theme-switch.svg do Rumda com máscara de opacidade.
// Clique alterna o modo via Styles.setColorMode().
Rectangle {
    id: root

    readonly property int moduleSize: 28
    readonly property int imageSourceSize: 55
    readonly property int maskWidth: 20
    readonly property int maskHeight: 18
    readonly property int maskRadius: 8

    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 4
    Layout.bottomMargin: 2

    width: moduleSize
    height: moduleSize
    radius: Styles.radiusSmall
    color: "transparent"
    clip: true

    Image {
        id: themeIcon
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/Icons/theme-switch.svg"
        sourceSize.width: imageSourceSize
        sourceSize.height: imageSourceSize
        fillMode: Image.PreserveAspectCrop
        scale: 1.0
        antialiasing: true
        smooth: true
        mipmap: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: root.maskWidth
                height: root.maskHeight
                radius: root.maskRadius
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Styles.setColorMode(Styles.colorMode === "dark" ? "light" : "dark")
        }
    }

    // Tooltip via status text (opcional)
    ToolTip.visible: hovered
    ToolTip.text: Styles.colorMode === "dark" ? "Alternar para modo claro" : "Alternar para modo escuro"
}