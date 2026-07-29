import QtQuick
import qs.Theme

// Campo de texto de uma linha só, com placeholder e borda que acende na cor
// de destaque quando focado. Usado no login/cadastro da Helena (usuário e,
// com passwordMode:true, a senha).
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
    property bool passwordMode: false
    readonly property alias input: input

    signal accepted()

    implicitHeight: 34
    implicitWidth: 180

    Rectangle {
        anchors.fill: parent
        radius: Colors.radiusInput
        color: Colors.surface
        border.color: input.activeFocus ? Colors.accent : Colors.border
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 8
            }
            text: root.placeholder
            color: Colors.foregroundMuted
            font.pixelSize: 12
            font.family: Colors.fontFamily
            visible: input.text.length === 0
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 8
            color: Colors.foreground
            font.pixelSize: 12
            font.family: Colors.fontFamily
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            selectByMouse: true
            echoMode: root.passwordMode ? TextInput.Password : TextInput.Normal
            onAccepted: root.accepted()
        }
    }
}
