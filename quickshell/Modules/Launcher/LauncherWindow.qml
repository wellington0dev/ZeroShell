import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.State
import qs.Widgets

PanelWindow {
    id: root

    IpcHandler {
        target: "launcher"

        // Bound to the Hyprland keybind that used to open rofi:
        // qs ipc call launcher toggle
        function toggle(): void {
            Visibility.launcherOpen = !Visibility.launcherOpen
        }
    }

    property string query: ""
    property int selectedIndex: 0

    readonly property var results: {
        const apps = DesktopEntries.applications.values
        let list = apps
        if (query.length > 0) {
            const q = query.toLowerCase()
            list = apps.filter(a =>
                (a.name && a.name.toLowerCase().includes(q)) ||
                (a.genericName && a.genericName.toLowerCase().includes(q)) ||
                (a.keywords && a.keywords.some(k => k.toLowerCase().includes(q)))
            )
        }
        return list.slice().sort((a, b) => a.name.localeCompare(b.name))
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        close()
    }

    function close() {
        Visibility.launcherOpen = false
    }

    onVisibleChanged: {
        if (visible) {
            query = ""
            selectedIndex = 0
            card.scale = 0.92
            card.opacity = 0
            // forceActiveFocus() right as the surface becomes visible can race
            // the compositor still mapping it, silently no-opping and leaving
            // nothing focused (so the next keypress falls through and closes
            // the launcher instead of typing). Deferring it a tick fixes that -
            // it also gives the pop-in Behaviors below a frame to kick in.
            Qt.callLater(() => {
                searchInput.forceActiveFocus()
                card.scale = 1
                card.opacity = 1
            })
        }
    }

    visible: Visibility.launcherOpen
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Shadow { target: card }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 480
        height: 420
        radius: Colors.radiusLarge
        color: Colors.background
        border.color: Colors.border
        border.width: 2

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.boing
            }
        }
        Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacing * 1.5
            spacing: Colors.spacing

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Colors.radiusSmall
                color: Colors.surface
                border.color: searchInput.activeFocus ? Colors.accent : Colors.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 120 } }

                TextInput {
                    id: searchInput

                    anchors.fill: parent
                    anchors.margins: 10
                    color: Colors.foreground
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    onTextChanged: {
                        root.query = text
                        root.selectedIndex = 0
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1, root.results.length - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launch(root.results[root.selectedIndex])
                            event.accepted = true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar aplicativos..."
                        color: Colors.foregroundMuted
                        font.pixelSize: 14
                        visible: searchInput.text.length === 0
                    }
                }
            }

            ListView {
                id: resultsList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.results
                currentIndex: root.selectedIndex
                highlightMoveDuration: 100

                delegate: AppEntry {
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: 48
                    entry: modelData
                    selected: index === root.selectedIndex
                    onActivated: root.launch(modelData)
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.results.length === 0
                text: "Nenhum aplicativo encontrado"
                color: Colors.foregroundMuted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
