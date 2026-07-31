import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State

// Aba "Ajustes" do Dashboard - toggles rápidos que não merecem abrir a
// janela inteira de Configurações. Cada linha é independente (ícone +
// nome + descrição curta + Switch), mesmo estilo de linha usado em
// DeviceRow.qml/DeviceOptionRow.qml das Configurações.
ColumnLayout {
    id: root

    spacing: Styles.spacing * 1.5

    Text {
        text: "Ajustes rápidos"
        color: Styles.foreground
        font.pixelSize: Styles.fontSizeLarge
        font.family: Styles.fontFamily
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Styles.spacing

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Styles.radiusButton
            color: Styles.surfaceAlt

            Icon {
                anchors.centerIn: parent
                icon: QuickSettings.notificationsEnabled ? "bell" : "eye-off"
                size: 18
                tint: Styles.foreground
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Notificações"
                color: Styles.foreground
                font.pixelSize: Styles.fontSizeNormal
                font.family: Styles.fontFamily
            }

            Text {
                text: "Desligado só esconde os popups - nada some do histórico."
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Switch {
            checked: QuickSettings.notificationsEnabled
            onToggled: QuickSettings.setNotificationsEnabled(!QuickSettings.notificationsEnabled)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Styles.spacing

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: Styles.radiusButton
            color: Styles.surfaceAlt

            Icon {
                anchors.centerIn: parent
                icon: "eye"
                size: 18
                tint: Styles.foreground
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Manter acordado"
                color: Styles.foreground
                font.pixelSize: Styles.fontSizeNormal
                font.family: Styles.fontFamily
            }

            Text {
                text: "Impede a tela de travar/suspender sozinha enquanto ligado."
                color: Styles.foregroundMuted
                font.pixelSize: Styles.fontSizeSmall
                font.family: Styles.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Switch {
            checked: QuickSettings.keepAwake
            onToggled: QuickSettings.setKeepAwake(!QuickSettings.keepAwake)
        }
    }

    Item { Layout.fillHeight: true }
}
