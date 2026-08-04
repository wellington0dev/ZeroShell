import QtQuick
import qs.Theme

// Como TextField.qml, mas pra senha: mostra bolinhas em vez do texto e tem um
// ícone de olho que alterna entre ocultar/revelar o conteúdo. Usado em
// Configurações > Wi-Fi (NetworkRow.qml) pra digitar a senha da rede.
//
// Por que é um componente separado de TextField em vez de só reaproveitar
// "passwordMode" de lá? Porque este precisa do botão de revelar dentro do
// próprio campo (empurrando o TextInput pra esquerda pra abrir espaço) - uma
// estrutura interna diferente o suficiente pra não valer a pena forçar os
// dois num só componente com muitos "if".
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool revealed: false

    signal accepted()

    implicitHeight: 30
    implicitWidth: 180

    Rectangle {
        anchors.fill: parent
        radius: Styles.radiusInput
        color: Styles.surface
        border.color: input.activeFocus ? Styles.accent : Styles.border
        border.width: 1

        Behavior on border.color {
            ColorAnimation { duration: Motion.durationFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.expressiveEffects }
        }

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
            }
            text: root.placeholder
            color: Styles.foregroundMuted
            font.pixelSize: 12
            font.family: Styles.fontFamily
            visible: input.text.length === 0
        }

        TextInput {
            id: input
            anchors {
                left: parent.left
                right: reveal.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 6
            }
            color: Styles.foreground
            font.pixelSize: 12
            font.family: Styles.fontFamily
            echoMode: root.revealed ? TextInput.Normal : TextInput.Password
            clip: true
            selectByMouse: true
            onAccepted: root.accepted()
        }

        // Botão de olho - clicar alterna entre mostrar a senha em texto puro
        // ou mascarada.
        Item {
            id: reveal
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 8
            }
            implicitWidth: 16
            implicitHeight: 16

            Icon {
                anchors.fill: parent
                icon: root.revealed ? "eye-off" : "eye"
                tint: Styles.foregroundMuted
            }

            TapHandler { onTapped: root.revealed = !root.revealed }
        }
    }
}
