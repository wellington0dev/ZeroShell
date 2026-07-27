import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.Theme
import qs.Widgets

// Card "hero" do grid bento - mais largo e com mais destaque que os
// RingMeter comuns, pensado pro item principal (CPU). Mistura um anel
// pequeno (só como selo do ícone) com rótulo e a porcentagem grande escrita
// por extenso ao lado, em vez de dentro do anel - inspirado no
// HeroCard.qml do caelestia (github.com/caelestia-dots/shell).
Rectangle {
    id: root

    property string icon
    property string label
    property string sublabel: ""
    property int percent: 0
    property color ringColor: Colors.accent

    readonly property real strokeW: 4

    radius: Colors.radiusLarge
    color: Colors.surface
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Item {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56

            Shape {
                id: shape

                anchors.fill: parent
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
                        startAngle: -225
                        sweepAngle: 270
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
                        startAngle: -225
                        sweepAngle: 270 * Math.max(0.01, Math.min(1, root.percent / 100))

                        Behavior on sweepAngle {
                            NumberAnimation { duration: Motion.durationSlow; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 20
                tint: root.ringColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.label
                color: root.ringColor
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.sublabel
                color: Colors.foregroundMuted
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                Layout.topMargin: 2
                text: root.percent + "%"
                color: Colors.foreground
                font.pixelSize: 28
                font.bold: true
            }
        }
    }
}
