import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Widgets

ColumnLayout {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    spacing: Styles.spacing

    function applyColor(key, value) {
        const props = {}
        props[key] = value.toString()
        Styles.setCustom(props)
        // Picking a color by hand means the palette is custom now - stop the
        // next wallpaper change from silently overwriting it.
        Styles.setUseWallpaperColors(false)
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
            color: Styles.foregroundMuted
            font.pixelSize: 11
            font.family: Styles.fontFamily
            Layout.fillWidth: true
        }

        Button {
            text: "Restaurar cores do wallpaper"
            primary: false
            onClicked: {
                const wp = (currentWallpaperFile.text() || "").trim()
                Styles.setUseWallpaperColors(true)
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
            spacing: Styles.spacing

            ColorSwatchRow { label: "Fundo"; key: "background"; value: Styles.background; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície"; key: "surface"; value: Styles.surface; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Superfície alternativa"; key: "surfaceAlt"; value: Styles.surfaceAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Borda"; key: "border"; value: Styles.border; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto"; key: "foreground"; value: Styles.foreground; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Texto secundário"; key: "foregroundMuted"; value: Styles.foregroundMuted; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque"; key: "accent"; value: Styles.accent; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Destaque alternativo"; key: "accentAlt"; value: Styles.accentAlt; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Perigo"; key: "danger"; value: Styles.danger; onChanged: (k, v) => root.applyColor(k, v) }
            ColorSwatchRow { label: "Sucesso"; key: "success"; value: Styles.success; onChanged: (k, v) => root.applyColor(k, v) }
        }
    }
}
