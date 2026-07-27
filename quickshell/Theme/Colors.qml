pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Paleta de cores e métricas compartilhadas por todo o shell (sidebar, settings,
// notificações, player, launcher, Helena, menu de energia...). Qualquer módulo
// importa "qs.Theme" e usa "Colors.accent", "Colors.spacing", etc.
//
// Por que isso é um singleton "estático" que lê um JSON via FileView, em vez de
// só ter as cores como propriedades comuns aqui dentro? Porque este arquivo tem
// "pragma Singleton" - e editar o CONTEÚDO de um arquivo pragma Singleton faz o
// Quickshell recarregar o módulo inteiro, fechando todas as janelas abertas.
// As cores, porém, mudam com frequência (troca de wallpaper via matugen, ou o
// usuário customizando na tela de Configurações > Aparência). Por isso os
// valores de verdade ficam em State/colors.json, e este arquivo só lê aquele
// JSON através de um FileView + JsonAdapter: quando o JSON muda, o FileView
// recarrega só os dados, sem fechar nada.
Singleton {
    id: root

    // Escreve uma ou mais cores diretamente em State/colors.json - usado pela
    // aba "Personalizar" das Configurações quando o usuário escolhe uma cor na
    // mão. Ex.: Colors.setCustom({accent: "#ff0000"}).
    function setCustom(props) {
        for (const key in props) adapter[key] = props[key]
        colorsFile.writeAdapter()
        // Mantém as cores de borda do Hyprland (hypr/theme_colors.lua)
        // sincronizadas com o que acabou de ser escolhido aqui, do mesmo jeito
        // que o apply-theme.sh faz depois de rodar o matugen.
        syncHyprProcess.running = true
    }

    Process {
        id: syncHyprProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/sync-hypr-colors.sh"]
    }

    // Se true, o script apply-theme.sh (chamado ao trocar de wallpaper) pode
    // regerar colors.json a partir do matugen. Se false, o usuário customizou
    // as cores na mão e uma troca de wallpaper não deve sobrescrever isso -
    // os próprios scripts bash em ~/.config/hypr/scripts leem este mesmo
    // arquivo (State/theme-mode.json) antes de decidir se regeram o tema.
    readonly property bool useWallpaperColors: modeAdapter.useWallpaperColors

    function setUseWallpaperColors(value) {
        modeAdapter.useWallpaperColors = value
        modeFile.writeAdapter()
    }

    FileView {
        id: modeFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/theme-mode.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: modeAdapter
            property bool useWallpaperColors: true
        }
    }

    // Fonte de verdade das cores. "adapter" é preenchido a partir do JSON no
    // disco assim que o arquivo é lido; os valores abaixo (com fallback
    // hardcoded) só aparecem antes da primeira leitura terminar ou se o
    // arquivo não existir ainda.
    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/colors.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // Superfícies base (fundo da sidebar, cards, etc.)
            property string background: "#1a1b26"
            property string surface: "#20212f"
            property string surfaceAlt: "#292a3a"
            property string border: "#33344a"

            // Texto
            property string foreground: "#c0caf5"
            property string foregroundMuted: "#565f89"

            // Destaques
            property string accent: "#7aa2f7"
            property string accentAlt: "#bb9af7"
            property string danger: "#f7768e"
            property string success: "#9ece6a"
        }
    }

    // As propriedades "color" de verdade que os componentes usam (o adapter
    // acima guarda strings hex; aqui elas viram o tipo "color" do QML).
    readonly property color background: adapter.background
    readonly property color surface: adapter.surface
    readonly property color surfaceAlt: adapter.surfaceAlt
    readonly property color border: adapter.border

    readonly property color foreground: adapter.foreground
    readonly property color foregroundMuted: adapter.foregroundMuted

    readonly property color accent: adapter.accent
    readonly property color accentAlt: adapter.accentAlt
    readonly property color danger: adapter.danger
    readonly property color success: adapter.success

    // Cores usadas pelos indicadores de workspace da sidebar (Workspaces.qml).
    readonly property color workspaceFocused: accent
    readonly property color workspaceActive: foregroundMuted
    readonly property color workspaceEmpty: surfaceAlt

    // Escala de arredondamento de cantos, usada em todo componente com
    // "radius:". Inspirada na escala do end-4/dots-hyprland (Material 3), com
    // valores menores porque nosso shell trabalha com superfícies menores.
    // radiusFull (9999) é o truque clássico pra fazer um cantoarredondado virar
    // um pill/círculo perfeito independente do tamanho do elemento.
    readonly property int radiusTiny: 4
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusFull: 9999

    // Espaçamento padrão usado em margins/spacing de layouts pelo shell todo.
    readonly property int spacing: 8

    readonly property string fontFamily: "sans-serif"

    // Escala de tamanho de fonte - use estes tokens em vez de números soltos
    // (ex.: font.pixelSize: Colors.fontSizeSmall) pra manter consistência.
    readonly property int fontSizeSmallest: 9
    readonly property int fontSizeSmaller: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeTitle: 16
}
