import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Um "tile" do grid bento da aba Ajustes (QuickSettingsTab.qml) - ícone no
// canto superior esquerdo, título + estado embaixo, Switch no canto
// inferior direito e, opcionalmente, um botão de engrenagem no canto
// superior direito pra quem tem aba própria nas Configurações (Wi-Fi/
// Bluetooth têm; Notificações/Manter acordado não, "showMore" fica false).
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string state: ""
    property bool checked: false
    property bool switchEnabled: true
    property bool showMore: false
    property bool moreActive: false

    signal toggled()
    signal moreClicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 110
    radius: Styles.radiusShell
    color: Styles.surfaceAlt
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Styles.spacing
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Icon {
                icon: root.icon
                size: 20
                tint: Styles.foreground
            }

            Item { Layout.fillWidth: true }

            IconButton {
                visible: root.showMore
                icon: "gear"
                size: 24
                active: root.moreActive
                onClicked: root.moreClicked()
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            text: root.title
            color: Styles.foreground
            font.pixelSize: Styles.fontSizeNormal
            font.family: Styles.fontFamily
            font.bold: true
        }

        Text {
            text: root.state
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Switch {
            Layout.alignment: Qt.AlignRight
            checked: root.checked
            enabled: root.switchEnabled
            onToggled: root.toggled()
        }
    }
}
