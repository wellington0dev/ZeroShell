import QtQuick
import qs.Theme

// Campo de texto de uma linha só, com placeholder e borda que acende na cor
// de destaque quando focado. Usado nos campos de texto simples das
// Configurações (ex.: pasta de destino em CapturePage.qml) - pra senha, ver
// PasswordField.qml (revela/oculta, ícone de olho).
//
// QML não tem um "TextField" pronto e temático fora do módulo QtQuick.Controls
// (que traria o próprio estilo nativo do sistema, difícil de recolorir); por
// isso construímos este em cima de um TextInput cru + um Text de placeholder
// que só aparece quando o campo está vazio.
//
// "input" é exposto como propriedade (readonly alias) pra quem usa poder
// chamar coisas como "usernameField.input.forceActiveFocus()" de fora.
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    readonly property alias input: input

    signal accepted()

    implicitHeight: 34
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
                leftMargin: 8
            }
            text: root.placeholder
            color: Styles.foregroundMuted
            font.pixelSize: 12
            font.family: Styles.fontFamily
            visible: input.text.length === 0
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 8
            color: Styles.foreground
            font.pixelSize: 12
            font.family: Styles.fontFamily
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            onAccepted: root.accepted()
        }
    }
}
