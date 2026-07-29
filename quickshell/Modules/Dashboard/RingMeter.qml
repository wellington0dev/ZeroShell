import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Card de monitor no estilo do caelestia (github.com/caelestia-dots/shell):
// cabeçalho com ícone+rótulo no canto superior esquerdo, e um "gauge" -
// anel de progresso com um vão embaixo (270° em vez de volta completa) -
// com a porcentagem grande centralizada dentro dele. Usa QtQuick.Shapes
// (PathAngleArc) em vez de Canvas: é declarativo e anima sozinho com
// Behavior, sem precisar chamar requestPaint manualmente.
Rectangle {
    id: root

    property string icon
    property string label
    property int percent: 0
    property color ringColor: Colors.accent

    readonly property int startAngle: -225
    readonly property int sweepAngle: 270
    readonly property real strokeW: 6

    radius: Colors.radiusShell
    color: Colors.surface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            Icon {
                icon: root.icon
                size: 13
                tint: root.ringColor
            }

            Text {
                text: root.label
                color: Colors.foregroundMuted
                font.pixelSize: 10
                font.family: Colors.fontFamily
            }
        }

        // O anel fica centralizado no espaço que sobra abaixo do
        // cabeçalho, em vez de no centro absoluto do card - assim a
        // distância header→anel fica sempre igual, não depende da altura
        // total do card.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Shape {
                id: shape

                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colors.surfaceAlt
                    strokeWidth: root.strokeW
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        radiusX: shape.width / 2 - root.strokeW / 2
                        radiusY: shape.height / 2 - root.strokeW / 2
                        centerX: shape.width / 2
                        centerY: shape.height / 2
                        startAngle: root.startAngle
                        sweepAngle: root.sweepAngle
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.ringColor
                    strokeWidth: root.strokeW
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        radiusX: shape.width / 2 - root.strokeW / 2
                        radiusY: shape.height / 2 - root.strokeW / 2
                        centerX: shape.width / 2
                        centerY: shape.height / 2
                        startAngle: root.startAngle
                        sweepAngle: root.sweepAngle * Math.max(0.01, Math.min(1, root.percent / 100))

                        Behavior on sweepAngle {
                            NumberAnimation { duration: Motion.durationSlow; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: shape
                text: root.percent + "%"
                color: root.ringColor
                font.pixelSize: 16
                font.family: Colors.fontFamily
                font.bold: true
            }
        }
    }
}
