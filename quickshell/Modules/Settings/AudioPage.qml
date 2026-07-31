import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Theme

Item {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing * 2

        Text {
            text: "Áudio"
            color: Styles.foreground
            font.pixelSize: 16
            font.family: Styles.fontFamily
            font.bold: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Text { text: "Saída"; color: Styles.foregroundMuted; font.pixelSize: 12 }

            VolumeRow {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSink
            }

            Repeater {
                model: root.outputs

                delegate: DeviceOptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    node: modelData
                    selected: Pipewire.defaultAudioSink === modelData
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Text { text: "Entrada"; color: Styles.foregroundMuted; font.pixelSize: 12 }

            VolumeRow {
                Layout.fillWidth: true
                node: Pipewire.defaultAudioSource
            }

            Repeater {
                model: root.inputs

                delegate: DeviceOptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    node: modelData
                    selected: Pipewire.defaultAudioSource === modelData
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
