import QtQuick
import Quickshell.Hyprland
import qs.Theme

// Indicadores de workspace do Hyprland - uma pilulazinha por workspace
// existente, que cresce e muda de cor quando é a focada. Clicar troca pra
// aquele workspace.
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
        // pilula visual de 10px - clicar num alvo tão pequeno quanto a pilula
        // sozinha seria frustrante. O retângulo de fundo só aparece no hover,
        // dando feedback de que ali é clicável.
        delegate: Item {
            id: hitArea

            required property var modelData

            width: 24
            height: 24

            Rectangle {
                anchors.centerIn: parent
                radius: Colors.radiusSmall
                width: parent.width
                height: parent.height
                color: hover.hovered ? Colors.surfaceAlt : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // A pilula em si: fica alta (24px) e na cor de destaque quando é
            // o workspace focado; um pontinho cinza quando só está "ativo"
            // (existe mas não é o visível agora, ex. noutro monitor); quase
            // invisível quando vazio.
            Rectangle {
                id: pill

                anchors.centerIn: parent
                width: 10
                height: hitArea.modelData.focused ? 24 : 10
                radius: 5
                color: hitArea.modelData.focused
                    ? Colors.workspaceFocused
                    : (hitArea.modelData.active ? Colors.workspaceActive : Colors.workspaceEmpty)

                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: hover }
            TapHandler {
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
