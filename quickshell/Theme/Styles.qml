pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Paleta de cores e métricas compartilhadas por todo o shell (sidebar, settings,
// notificações, player, launcher, menu de energia...). Qualquer módulo
// importa "qs.Theme" e usa "Styles.accent", "Styles.spacing", etc. Chama-se
// "Styles" (não "Colors" - nome antigo do arquivo) porque já não é só cor:
// raio, espaçamento, fonte e as margens de painel também moram aqui.
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
    // mão. Ex.: Styles.setCustom({accent: "#ff0000"}).
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

    // Algoritmo de esquema de cor do matugen - um dos "--type" (scheme-
    // content, scheme-expressive, etc, ver Modules/Settings/WallpaperGrid.qml
    // pra lista completa e hypr/scripts/apply-theme.sh pra onde isso é lido
    // e passado pro matugen). Hoje só afeta "danger"/"success" - fundo/
    // superfície/borda/texto E accent/accentAlt vêm todos de amostragem
    // direta da imagem (extract-colors.py), não do algoritmo do matugen,
    // desde que "background" precisou ficar tingido pela cor do wallpaper
    // também no modo claro (o "background" nativo do matugen nesse --type
    // fica quase branco puro no claro, sem matiz nenhum).
    readonly property string schemeType: modeAdapter.schemeType

    function setSchemeType(value) {
        modeAdapter.schemeType = value
        modeFile.writeAdapter()
    }

    // Claro/escuro pras cores derivadas do wallpaper - o "--mode" do
    // matugen (só "dark"/"light", ver hypr/scripts/apply-theme.sh e
    // Modules/Settings/WallpaperGrid.qml). Sem efeito nenhum quando
    // useWallpaperColors é false (tema fixo/preset não usa matugen).
    readonly property string colorMode: modeAdapter.colorMode

    function setColorMode(value) {
        modeAdapter.colorMode = value
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
            property string schemeType: "scheme-neutral"
            property string colorMode: "dark"
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

    // Raio de canto CONFIGURÁVEL por categoria (Configurações > Aparência >
    // Raio), separado da escala fixa acima. A escala fixa continua servindo
    // pra elementos decorativos/estruturais onde não faz sentido o usuário
    // escolher (avatares circulares, pilulas de status, swatches) - só
    // painéis do shell, botões e inputs têm um raio próprio configurável,
    // porque cada categoria tem proporções bem diferentes (um painel inteiro
    // e um botãozinho não deveriam ser forçados pro mesmo número).
    readonly property int radiusShell: radiusAdapter.shell
    readonly property int radiusButton: radiusAdapter.button
    readonly property int radiusInput: radiusAdapter.input
    // Raio das janelas do Hyprland (decoration.rounding) - não é algo que
    // este QML desenha; RadiusCustomizer.qml (Settings > Aparência) escreve
    // esse valor tanto aqui (JSON, pra UI lembrar o que tá salvo) quanto em
    // hypr/window_radius.lua + "hyprctl reload" (o que de fato aplica).
    readonly property int radiusWindow: radiusAdapter.window

    // Se true, mudar QUALQUER categoria muda as 4 juntas pro mesmo valor -
    // pra quem só quer um raio só no lugar de ajustar shell/botão/input/
    // janela um por um. Controlado pelo toggle "Manter alinhado" no topo do
    // RadiusCustomizer.qml.
    readonly property bool radiusLinked: radiusAdapter.linked

    function setRadius(key, value) {
        if (radiusAdapter.linked) {
            radiusAdapter.shell = value
            radiusAdapter.button = value
            radiusAdapter.input = value
            radiusAdapter.window = value
        } else {
            radiusAdapter[key] = value
        }
        radiusFile.writeAdapter()
    }

    function setRadiusLinked(value) {
        radiusAdapter.linked = value
        // Ao ligar o alinhamento, unifica tudo no valor do shell na hora -
        // senão "ligado" ficaria mentindo (os 4 sliders continuariam
        // mostrando números diferentes até a próxima mudança).
        if (value) {
            const v = radiusAdapter.shell
            radiusAdapter.button = v
            radiusAdapter.input = v
            radiusAdapter.window = v
        }
        radiusFile.writeAdapter()
    }

    // Sem "watchChanges"/"onFileChanged: reload()" de propósito: só este
    // singleton (via setRadius) escreve nesse arquivo. Reagir à própria
    // escrita já causou um bug real de duplicação num JSON parecido
    // (NotificationService.qml) - aqui os valores são escalares, não um
    // array, então não duplicariam, mas o auto-reload seria só trabalho
    // supérfluo mesmo assim.
    FileView {
        id: radiusFile
        path: Quickshell.env("HOME") + "/.config/quickshell/State/radius-config.json"

        JsonAdapter {
            id: radiusAdapter
            property int shell: 20
            property int button: 16
            property int input: 12
            property int window: 12
            property bool linked: false
        }
    }

    // Espaçamento padrão usado em margins/spacing de layouts pelo shell todo.
    readonly property int spacing: 8

    // Distância padrão entre um painel flutuante (Dashboard, Launcher,
    // menu de energia, menu de captura, volume) e a borda da tela mais
    // próxima quando aberto - um valor só, pra não ficar cada painel com o
    // seu (era 10/12/20 espalhado antes disso existir).
    readonly property int edgeMargin: 10

    // Margem extra (em vez de edgeMargin) só pro lado que fica colado na
    // sidebar (56px de largura + 10 de folga) - painéis que nascem no canto
    // esquerdo (menu de energia) usam isto pra não ficar embaixo dela. Não
    // é "distância da borda" no sentido geral, por isso é um token
    // separado.
    readonly property int sidebarClearance: 76

    // JetBrainsMono Nerd Font - instalada pelo install.sh (pacote
    // ttf-jetbrains-mono-nerd). QtQuick "Text"/"TextInput"/"TextEdit" puros
    // (sem QtQuick Controls) não herdam "font" de um ancestral, e
    // "Qt.application.font" é somente-leitura em QML - por isso
    // "font.family: Styles.fontFamily" é repetido ao lado de cada
    // "font.pixelSize:" do shell, em vez de setado num lugar só.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // Escala de tamanho de fonte - use estes tokens em vez de números soltos
    // (ex.: font.pixelSize: Styles.fontSizeSmall) pra manter consistência.
    readonly property int fontSizeSmallest: 9
    readonly property int fontSizeSmaller: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeTitle: 16
}
