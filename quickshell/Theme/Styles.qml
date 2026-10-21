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

    // Só persiste a escolha - NÃO muda cor nenhuma na tela.
    //
    // As cores de verdade do shell vivem em State/colors.json e quem as gera é o
    // matugen dentro de hypr/scripts/apply-theme.sh. Por isso, chamar SÓ o
    // setColorMode (o que o botão antigo da sidebar fazia) não mudava NADA na
    // tela: o JSON era reescrito com "light" e as cores continuavam as
    // antigas. Use applyColorMode (abaixo) pra trocar de fato.
    function setColorMode(value) {
        modeAdapter.colorMode = value
        modeFile.writeAdapter()
    }

    // Aplica o modo "dark"/"light" de verdade: persiste a escolha e roda o
    // apply-theme.sh com o wallpaper atual pra regerar colors.json (e as bordas
    // do Hyprland, que o próprio script sincroniza). O FileView do colors.json
    // (/State/colors.json, ver "adapter" abaixo) pega a mudança ao vivo, sem
    // recarregar o shell.
    //
    // É o mesmo caminho de Modules/Settings/WallpaperGrid.pickColorMode, que
    // agora só delega pra cá - um lugar só com a lógica de "aplicar tema".
    function applyColorMode(value) {
        setColorMode(value)

        // O wallpaper é lido de um FileView, que carrega assíncrono. Se o
        // clique chegar antes (shell acabando de abrir), esperar em vez de
        // desistir - senão o modo fica salvo no JSON e a tela não muda, que é
        // exatamente o bug do botão antigo.
        applyThemeRetry.attempts = 0
        applyThemeRetry.restart()
    }

    // Wallpaper em uso agora - o mesmo arquivo que o Hyprland escreve quando a
    // tela de fundo muda (~/.cache/hypr/wallpaper_current, lido igual em
    // Modules/Settings/WallpaperGrid.qml). O apply-theme.sh exige o caminho
    // da imagem como argumento, então é daqui que ele sai.
    FileView {
        id: currentWallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: applyThemeProcess
    }

    // Tenta rodar o apply-theme.sh a cada 300ms, no máximo 10 vezes (3s): dá
    // tempo do FileView do wallpaper terminar de carregar sem deixar um retry
    // infinito rodando quando o arquivo não existir.
    Timer {
        id: applyThemeRetry
        interval: 300
        repeat: true
        property int attempts: 0

        onTriggered: {
            const wallpaper = (currentWallpaperFile.text() || "").trim()
            if (wallpaper) {
                stop()
                applyThemeProcess.command = ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/apply-theme.sh", wallpaper]
                applyThemeProcess.running = true
            } else if (++attempts >= 10) {
                stop()
                console.warn("Styles: apply-theme.sh não rodou - wallpaper atual indisponível em ~/.cache/hypr/wallpaper_current")
            }
        }
    }

    // Retorna o wallpaper salvo para o modo especificado ("dark" ou "light"),
    // ou string vazia se não houver wallpaper salvo para esse modo.
    function wallpaperForMode(mode) {
        if (mode === "light") return modeAdapter.wallpaper_light
        else return modeAdapter.wallpaper_dark
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
            // Wallpapers por modo (Fase 5) - caminhos absolutos ou vazios.
            // Se vazio, o apply-theme.sh cai no fallback para wallpaper_current (legado).
            property string wallpaper_dark: ""
            property string wallpaper_light: ""
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

    // ---- Tamanhos dos controles da barra ----
    // Fonte única do tamanho de tile/ícone. Antes cada módulo trazia o número
    // no seu próprio corpo (o do Rumda misturava 26, 28 e 30 na mesma barra,
    // e o botão de wifi da horizontal ficava 36 enquanto os vizinhos ficavam
    // 30). Tudo agora sai daqui, então tile com tile tem a mesma medida.
    readonly property int control: 30    // lado do tile de ação (quadrado)
    readonly property int controlSmall: 26  // tile de ação compacta
    readonly property int controlIcon: 16    // ícone dentro do tile de 30
    readonly property int controlIconLarge: 20   // ícone dos módulos maiores (potência)
    readonly property int controlRing: 22    // anel de CPU/RAM
    readonly property int controlPill: 9     // altura da pílula de workspace

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

    // =====================================================================
    // Paleta RUMDA — tokens de referência (Fase 1 da migração)
    // =====================================================================
    // Cores FIXAS copiadas literalmente de:
    //   ~/.config/rumda/common/quickshell/{dark,light}/config/Colors.qml
    //
    // São PALETA DE REFERÊNCIA, não o tema do shell. Os componentes
    // continuam usando os tokens acima (background/surface/accent/...),
    // que vêm do matugen e mudam com o wallpaper. Nada aqui é lido de
    // State/colors.json e nada aqui é gravado por setCustom().
    //
    // Por que prefixo 'rumda': os arquivos de origem usam nomes genéricos
    // (accentColor, borderColor, moduleBG...) que colidiriam com os tokens
    // existentes deste arquivo. O prefixo mantém a correspondência 1:1 com
    // o nome de origem, documentado na linha de cada token, para portar um
    // componente do Rumda sem risco de pegar o token errado.
    //
    // CONTAGEM REAL (medida nos arquivos de origem, não presumida):
    //   dark  = 20 declarações -> 15 valores distintos
    //   light = 21 declarações -> 17 valores distintos
    //
    // Duplicatas dentro do dark:
    //   #3A2D22 = borderColor, dashBorderColor
    //   #3d2e21 = moduleBG, dashModulesColor
    //   #c47c4f = accentColor, accent2Color
    //   #2b221a = dashBGColor, dashPFPColor, powerButtons
    // Duplicatas dentro do light:
    //   #f2bc88 = borderColor, dashBorderColor, dashAccentColor
    //   #F5DCC6 = dashBGColor, dashPFPColor, powerButtons
    // Iguais em dark E light: accent2Color (#c47c4f), errorColor (#9A4235)
    //
    // Apenas no light: zoomTint. Ausente no dark.
    // 'dashAccentColor' está marcado 'ignore this' pelo AUTOR nos dois
    // arquivos — mantido por fidelidade, mas não usar.
    // =====================================================================

    // ---- DARK ----
    readonly property color rumdaDarkBackgroundColor: "#1c1612"  // <- backgroundColor (cor da barra)
    readonly property color rumdaDarkIndicatorBGColor: "#f0bb90"  // <- indicatorBGColor
    readonly property color rumdaDarkBorderColor: "#3A2D22"  // <- borderColor
    readonly property color rumdaDarkModuleBG: "#3d2e21"  // <- moduleBG
    readonly property color rumdaDarkAccentColor: "#c47c4f"  // <- accentColor
    readonly property color rumdaDarkAccent2Color: "#c47c4f"  // <- accent2Color
    readonly property color rumdaDarkGradientAccent2Color: "#d68e60"  // <- gradientAccent2Color (base/direita da barra de volume)
    readonly property color rumdaDarkErrorColor: "#9A4235"  // <- errorColor
    readonly property color rumdaDarkShadowColor: "#CC784d37"  // <- shadowColor (8 dígitos: inclui alfa; vale também p/ a sombra do dashboard — desativável via Config)
    readonly property color rumdaDarkDashBGColor: "#2b221a"  // <- dashBGColor
    readonly property color rumdaDarkDashModulesColor: "#3d2e21"  // <- dashModulesColor (módulos/retângulos internos)
    readonly property color rumdaDarkDashBorderColor: "#3A2D22"  // <- dashBorderColor (bordas / círculo em volta do pfp)
    readonly property color rumdaDarkDashPFPColor: "#2b221a"  // <- dashPFPColor (círculo do pfp)
    readonly property color rumdaDarkLevel0Contrib: "#5c3d2d"  // <- level0Contrib
    readonly property color rumdaDarkLevel1Contrib: "#9e6d54"  // <- level1Contrib
    readonly property color rumdaDarkLevel2Contrib: "#cf9174"  // <- level2Contrib
    readonly property color rumdaDarkLevel3Contrib: "#db9d7f"  // <- level3Contrib
    readonly property color rumdaDarkLevel4Contrib: "#f7b292"  // <- level4Contrib
    readonly property color rumdaDarkPowerButtons: "#2b221a"  // <- powerButtons (bg dos botões)
    readonly property color rumdaDarkDashAccentColor: "#3A2D00"  // <- dashAccentColor ("ignore this" no autor; por fidelidade, não usar)
    // (duplicatas em dark: #3A2D22 = borderColor, dashBorderColor; #3d2e21 = moduleBG, dashModulesColor; #c47c4f = accentColor, accent2Color; #2b221a = dashBGColor, dashPFPColor, powerButtons)

    // ---- LIGHT ----
    readonly property color rumdaLightBackgroundColor: "#f0c997"  // <- backgroundColor (cor da barra)
    readonly property color rumdaLightIndicatorBGColor: "#dba380"  // <- indicatorBGColor
    readonly property color rumdaLightBorderColor: "#f2bc88"  // <- borderColor
    readonly property color rumdaLightModuleBG: "#f0bb90"  // <- moduleBG
    readonly property color rumdaLightAccentColor: "#a1694d"  // <- accentColor
    readonly property color rumdaLightAccent2Color: "#c47c4f"  // <- accent2Color
    readonly property color rumdaLightGradientAccent2Color: "#a87358"  // <- gradientAccent2Color (base/direita da barra de volume)
    readonly property color rumdaLightErrorColor: "#9A4235"  // <- errorColor
    readonly property color rumdaLightShadowColor: "#AA784d37"  // <- shadowColor (8 dígitos: inclui alfa)
    readonly property color rumdaLightDashBGColor: "#F5DCC6"  // <- dashBGColor
    readonly property color rumdaLightDashModulesColor: "#f2cdac"  // <- dashModulesColor (módulos/retângulos internos)
    readonly property color rumdaLightDashBorderColor: "#f2bc88"  // <- dashBorderColor (bordas / círculo em volta do pfp)
    readonly property color rumdaLightDashPFPColor: "#F5DCC6"  // <- dashPFPColor (círculo do pfp)
    readonly property color rumdaLightLevel0Contrib: "#db986e"  // <- level0Contrib
    readonly property color rumdaLightLevel1Contrib: "#ba7245"  // <- level1Contrib
    readonly property color rumdaLightLevel2Contrib: "#9e5b2f"  // <- level2Contrib
    readonly property color rumdaLightLevel3Contrib: "#8f4f24"  // <- level3Contrib
    readonly property color rumdaLightLevel4Contrib: "#7d431f"  // <- level4Contrib
    readonly property color rumdaLightPowerButtons: "#F5DCC6"  // <- powerButtons (bg dos botões)
    readonly property color rumdaLightDashAccentColor: "#f2bc88"  // <- dashAccentColor ("ignore this" no autor; por fidelidade, não usar)
    readonly property color rumdaLightZoomTint: "#000000"  // <- zoomTint (existe SÓ no light)
    // (duplicatas em light: #f2bc88 = borderColor, dashBorderColor, dashAccentColor; #F5DCC6 = dashBGColor, dashPFPColor, powerButtons)
}
