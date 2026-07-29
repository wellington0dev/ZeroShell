import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string wallpapersDir: Quickshell.env("HOME") + "/Wallpapers"

    spacing: Colors.spacing

    FileView {
        id: currentFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
        watchChanges: true
        onFileChanged: reload()
    }

    readonly property string current: (currentFile.text() || "").trim()

    function run(args) {
        applyProcess.command = args
        applyProcess.running = true
    }

    Process { id: applyProcess }

    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacing

        Button {
            text: "Anterior"
            primary: false
            onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "prev"])
        }

        Button {
            text: "Aleatório"
            onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "random"])
        }

        Button {
            text: "Próximo"
            primary: false
            onClicked: root.run(["bash", root.scriptsDir + "/toggle-wallpaper.sh", "next"])
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "Cores do wallpaper"
            color: Colors.foreground
            font.pixelSize: 12
            font.family: Colors.fontFamily
        }

        Switch {
            checked: Colors.useWallpaperColors
            onToggled: {
                const next = !Colors.useWallpaperColors
                Colors.setUseWallpaperColors(next)
                // Sync immediately instead of waiting for the next wallpaper change.
                if (next && root.current) root.run(["bash", root.scriptsDir + "/apply-theme.sh", root.current])
            }
        }
    }

    GridView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: 132
        cellHeight: 82
        model: FolderListModel {
            folder: "file://" + root.wallpapersDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
            showDirs: false
            sortField: FolderListModel.Name
        }

        delegate: Item {
            width: 124
            height: 74

            required property string filePath
            required property url fileUrl

            Rectangle {
                anchors.fill: parent
                radius: Colors.radiusSmall
                color: Colors.surfaceAlt
                border.width: filePath === root.current ? 2 : 0
                border.color: Colors.accent
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    source: fileUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 132
                    sourceSize.height: 82
                }
            }

            TapHandler {
                onTapped: root.run(["bash", root.scriptsDir + "/set-wallpaper.sh", filePath])
            }
        }
    }
}
