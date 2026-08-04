import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Theme
import qs.Widgets
import qs.State

// Aba "Dock" das Configurações - escolhe quais apps instalados ficam
// fixados no dock (Modules/Dock/DockWindow.qml). Mesma fonte de apps do
// Launcher (Quickshell.DesktopEntries), com busca igual a
// LauncherWindow.qml - só que aqui é uma lista fixa com Switch por linha
// em vez de um resultado clicável só.
Item {
    id: root

    property string query: ""

    readonly property var apps: {
        const list = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        const sorted = list.slice().sort((a, b) => a.name.localeCompare(b.name))
        if (root.query.length === 0) return sorted
        const q = root.query.toLowerCase()
        return sorted.filter(a => a.name.toLowerCase().includes(q))
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing

        Text {
            text: "Dock"
            color: Styles.foreground
            font.pixelSize: 16
            font.family: Styles.fontFamily
            font.bold: true
        }

        Text {
            text: "Escolha quais aplicativos ficam fixados no dock. Apps rodando que não estão fixados aparecem lá do mesmo jeito enquanto estiverem abertos."
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            Layout.fillWidth: true
            placeholder: "Buscar aplicativos..."
            onTextChanged: root.query = text
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.apps

            delegate: RowLayout {
                id: appRow

                required property var modelData

                width: ListView.view.width
                spacing: Styles.spacing

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Styles.radiusSmall
                    color: Styles.surfaceAlt

                    IconImage {
                        id: iconImage
                        anchors.centerIn: parent
                        implicitSize: 20
                        source: Quickshell.iconPath(appRow.modelData.icon, true)
                    }

                    Icon {
                        anchors.centerIn: parent
                        visible: iconImage.status !== Image.Ready
                        icon: "window"
                        size: 16
                        tint: Styles.foregroundMuted
                    }
                }

                Text {
                    text: appRow.modelData.name
                    color: Styles.foreground
                    font.pixelSize: Styles.fontSizeSmall
                    font.family: Styles.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Switch {
                    checked: DockConfig.isPinned(appRow.modelData.id)
                    onToggled: DockConfig.setPinned(appRow.modelData.id, !DockConfig.isPinned(appRow.modelData.id))
                }
            }
        }

        Text {
            visible: root.apps.length === 0
            text: "Nenhum aplicativo encontrado"
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
