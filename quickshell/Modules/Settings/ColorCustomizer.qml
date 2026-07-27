import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    spacing: Colors.spacing

    function applyColor(key, value) {
        const props = {}
        props[key] = value.toString()
        Colors.setCustom(props)
        // Picking a color by hand means the palette is custom now - stop the
        // next wallpaper change from silently overwriting it.
        Colors.setUseWallpaperColors(false)
    }

    FileView {
        id: currentWallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
    }

    Process {
        id: resetProcess
        function run(args) { command = args; running = true }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Cada cor é salva assim que você escolhe."
            color: Colors.foregroundMuted
            font.pixelSize: 11
            Layout.fillWidth: true
        }

        Button {
            text: "Restaurar cores do wallpaper"
            primary: false
            onClicked: {
                const wp = (currentWallpaperFile.text() || "").trim()
                Colors.setUseWallpaperColors(true)
                if (wp) resetProcess.run(["bash", root.scriptsDir + "/apply-theme.sh", wp])
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: list.implicitHeight
        clip: true

        ColumnLayout {
            id: list
            width: parent.width
            spacing: Colors.spacing

            ColorSwatchRow { label: "Fundo"; key: "background"; value: Colors.background; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície"; key: "surface"; value: Colors.surface; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície alternativa"; key: "surfaceAlt"; value: Colors.surfaceAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Borda"; key: "border"; value: Colors.border; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto"; key: "foreground"; value: Colors.foreground; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto secundário"; key: "foregroundMuted"; value: Colors.foregroundMuted; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque"; key: "accent"; value: Colors.accent; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque alternativo"; key: "accentAlt"; value: Colors.accentAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Perigo"; key: "danger"; value: Colors.danger; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Sucesso"; key: "success"; value: Colors.success; onChanged: (k, v) => root.applyColor(k, v) }
        }
    }
}
