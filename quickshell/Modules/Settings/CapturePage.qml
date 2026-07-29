import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.Theme
import qs.Widgets
import qs.Modules.Capture

// Aba de Configurações pra captura/gravação de tela: onde salvar os
// arquivos e duas opções rápidas (copiar pro clipboard, notificar). Lê e
// grava direto em CaptureService (Modules/Capture/CaptureService.qml), que é
// quem persiste isso em State/capture-settings.json.
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: Colors.spacing * 1.5

        Text {
            text: "Captura de tela"
            color: Colors.foreground
            font.pixelSize: 16
            font.family: Colors.fontFamily
            font.bold: true
        }

        // ---- Pasta de screenshots ----
        Text {
            text: "Pasta das capturas"
            color: Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            font.family: Colors.fontFamily
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacing

            TextField {
                id: screenshotsField
                Layout.fillWidth: true
                text: CaptureService.screenshotsDir
                onAccepted: CaptureService.saveSettings({ screenshotsDir: text })
            }

            IconButton {
                icon: "folder"
                onClicked: screenshotsDirDialog.open()
            }
        }

        // ---- Pasta de gravações ----
        Text {
            text: "Pasta das gravações"
            color: Colors.foregroundMuted
            font.pixelSize: Colors.fontSizeSmall
            font.family: Colors.fontFamily
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacing

            TextField {
                id: videosField
                Layout.fillWidth: true
                text: CaptureService.videosDir
                onAccepted: CaptureService.saveSettings({ videosDir: text })
            }

            IconButton {
                icon: "folder"
                onClicked: videosDirDialog.open()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacing / 2
            Layout.preferredHeight: 1
            color: Colors.border
        }

        // ---- Opções rápidas ----
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Copiar captura para a área de transferência"
                color: Colors.foreground
                font.pixelSize: Colors.fontSizeSmall
                font.family: Colors.fontFamily
                Layout.fillWidth: true
            }

            Switch {
                checked: CaptureService.copyToClipboard
                onToggled: CaptureService.saveSettings({ copyToClipboard: !CaptureService.copyToClipboard })
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notificar ao terminar captura/gravação"
                color: Colors.foreground
                font.pixelSize: Colors.fontSizeSmall
                font.family: Colors.fontFamily
                Layout.fillWidth: true
            }

            Switch {
                checked: CaptureService.notifyOnCapture
                onToggled: CaptureService.saveSettings({ notifyOnCapture: !CaptureService.notifyOnCapture })
            }
        }

        Item { Layout.fillHeight: true }
    }

    FolderDialog {
        id: screenshotsDirDialog
        title: "Escolher pasta das capturas"
        currentFolder: "file://" + CaptureService.screenshotsDir
        onAccepted: {
            const path = decodeURIComponent(selectedFolder.toString().replace("file://", ""))
            CaptureService.saveSettings({ screenshotsDir: path })
        }
    }

    FolderDialog {
        id: videosDirDialog
        title: "Escolher pasta das gravações"
        currentFolder: "file://" + CaptureService.videosDir
        onAccepted: {
            const path = decodeURIComponent(selectedFolder.toString().replace("file://", ""))
            CaptureService.saveSettings({ videosDir: path })
        }
    }
}
