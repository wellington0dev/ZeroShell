import QtQuick
import Quickshell.Hyprland
import qs.Theme

// Indicadores de workspace do Hyprland - uma pilulazinha por workspace
// existente, que cresce, ganha o número e muda de cor quando é a focada.
// Clicar troca pra aquele workspace.
//
// "Hyprland.workspaces" vem do módulo Quickshell.Hyprland e já se atualiza
// sozinho conforme workspaces são criados/destruídos/trocados - não
// precisamos escutar eventos manualmente.
Column {
    id: root

    spacing: 4

    Repeater {
        model: Hyprland.workspaces.values

        // Cada delegate é um quadrado de 24x24 (a área clicável) maior que a
        // pilula visual - clicar num alvo tão pequeno quanto a pilula sozinha
        // seria frustrante. O retângulo de fundo só aparece no hover, dando
        // feedback de que ali é clicável; um leve encolhimento no toque
        // (scale) reforça que o clique registrou.
        delegate: Item {
            id: hitArea

            required property var modelData

            width: 24
            height: 24
            scale: tap.pressed ? 0.88 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: Motion.durationFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standard
                }
            }

            Rectangle {
                anchors.centerIn: parent
                radius: Styles.radiusFull
                width: parent.width
                height: parent.height
                color: hover.hovered ? Styles.surfaceAlt : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // A pilula em si: alta e larga o bastante pro número quando é o
            // workspace focado; um pontinho médio quando só está "ativo"
            // (existe mas não é o visível agora, ex. noutro monitor); um
            // pontinho pequeno e semitransparente quando só existe, vazio.
            Rectangle {
                id: pill

                anchors.centerIn: parent
                width: hitArea.modelData.focused ? 20 : (hitArea.modelData.active ? 12 : 8)
                height: hitArea.modelData.focused ? 24 : (hitArea.modelData.active ? 12 : 8)
                radius: Styles.radiusFull
                color: hitArea.modelData.focused
                    ? Styles.workspaceFocused
                    : (hitArea.modelData.active ? Styles.workspaceActive : Styles.workspaceEmpty)
                opacity: hitArea.modelData.focused || hitArea.modelData.active ? 1 : 0.5

                Behavior on width {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.expressiveDefaultSpatial
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.expressiveDefaultSpatial
                    }
                }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    visible: hitArea.modelData.focused
                    opacity: parent.width > 16 ? 1 : 0
                    text: hitArea.modelData.id
                    color: Styles.background
                    font.pixelSize: Styles.fontSizeSmallest
                    font.family: Styles.fontFamily
                    font.bold: true

                    Behavior on opacity { NumberAnimation { duration: Motion.durationFast } }
                }
            }

            HoverHandler { id: hover }
            TapHandler {
                id: tap
                // Este Hyprland (veja hyprland.lua) interpreta a string de
                // dispatch como Lua, então a sintaxe padrão "workspace <id>"
                // do Hyprland comum NÃO funciona aqui - precisa ser uma
                // chamada hl.dsp de verdade, igual aos keybinds do
                // hyprland.lua. Descoberto testando ao vivo: o dispatch
                // falhava silenciosamente com a sintaxe "normal".
                onTapped: Hyprland.dispatch("hl.dsp.focus({workspace = " + hitArea.modelData.id + "})")
            }
        }
    }
}
