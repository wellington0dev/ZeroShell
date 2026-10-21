import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Sidebar.RumdaBarSections
import qs.Modules.Sidebar.RumdaBarModules
import qs.Modules.Sidebar.RumdaConfig

// Sidebar baseada na barra do Rumda (pistachio), adaptada para vertical
PanelWindow {
    id: root

    readonly property int shellWidth: 56
    readonly property int outerGapV: 30
    readonly property int outerGapH: 10
    readonly property int shadowPad: 10

    implicitWidth: shellWidth + shadowPad * 2
    exclusiveZone: shellWidth
    color: "transparent"
    margins{
        top: outerGapV - shadowPad
        left: outerGapH - shadowPad
        bottom: outerGapV - shadowPad
    }

    anchors {
        top: true
        bottom: true
        left: true
    }

    mask: Region { item: bg }

    IdleInhibitor {
        window: root
        enabled: QuickSettings.keepAwake
    }

    Shadow { target: bg }

    Rectangle {
        id: bg
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: shadowPad
        width: shellWidth
        color: Styles.background
        border.color: Styles.border
        radius: Styles.radiusShell
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Styles.spacing
            spacing: Styles.spacing

            // TopSection: Clock + Volume + CPU/RAM
            TopSection {}

            // Espaçador elástico
            Item { Layout.fillHeight: true }

            // CenterSection: Workspaces
            CenterSection {}

            // Espaçador elástico
            Item { Layout.fillHeight: true }

            // BottomSection: ThemeSwitch + Weather + Internet + Power
            BottomSection {}
        }
    }
}