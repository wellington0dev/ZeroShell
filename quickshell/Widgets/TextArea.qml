import QtQuick
import qs.Theme

// Campo de texto multi-linha, mesmo estilo do TextField.qml (borda que
// acende no foco, placeholder) só que com TextEdit+wrapMode em vez de
// TextInput - usado na caixa de mensagem do chat e no editor do system
// prompt (Modules/Settings não tinha nenhum multi-linha até agora).
//
// Enter sozinho dispara "accepted()" (o chamador decide o que fazer -
// tipicamente "enviar"); Shift+Enter insere uma quebra de linha normal.
Item {
    id: root

    property alias text: input.text
    property string placeholder: ""
    readonly property alias input: input

    signal accepted()

    implicitHeight: 80
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
            anchors { left: parent.left; top: parent.top; margins: 8 }
            text: root.placeholder
            color: Styles.foregroundMuted
            font.pixelSize: 12
            font.family: Styles.fontFamily
            visible: input.text.length === 0
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            contentHeight: input.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
                id: input
                width: parent.width
                color: Styles.foreground
                font.pixelSize: 12
                font.family: Styles.fontFamily
                wrapMode: TextEdit.Wrap
                selectByMouse: true

                Keys.onPressed: (event) => {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = true
                        root.accepted()
                    }
                }
            }
        }
    }
}
