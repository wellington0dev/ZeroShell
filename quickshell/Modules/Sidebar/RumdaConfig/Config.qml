pragma Singleton

import QtQuick
import Quickshell
import qs.Theme
import qs.State

// Configuração compatível com ZeroShell baseada no Rumda pistachio
// Substitui o qs.shared do Rumda pelos singletons do ZeroShell
Singleton {
    id: root

    // Screen info - usa o Screen do Qt
    readonly property int screenHeight: Screen.height
    readonly property int screenWidth: Screen.width

    // User Configuration - usa variáveis de ambiente
    // "Qt.getenv" foi removido no Qt6 (TypeError em runtime) - no Quickshell
    // quem lê variável de ambiente é "Quickshell.env".
    readonly property string username: Quickshell.env("USER")
    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/Modules/Sidebar/RumdaConfig"

    readonly property string profilePath: Quickshell.env("HOME") + "/.face"
    readonly property string fileManager: "xdg-open"
    readonly property string browser: "xdg-open"
    readonly property string terminal: "alacritty"

    // Bar Configuration - adaptado do Rumda pistachio
    readonly property int barMarginTop: 80
    readonly property int barMarginBottom: 80
    readonly property int barMarginLeft: 18
    readonly property int barMarginRight: 1
    readonly property int barWidth: 56
    // Raios: seguem os tokens do shell (Styles.radiusShell / radiusButton),
    // que são os que Configurações > Aparência > Raio ajusta. Os números do
    // Rumda (8/7/9/12) eram fixos, então o card do Dashboard ficava com
    // cantos arredondados mesmo com o raio do shell em 0 - e os botões dele
    // usavam um raio que não tinha nada a ver com o dos botões do resto do
    // shell.
    // Painéis do shell (card do dashboard e os módulos dentro dele).
    readonly property int barRadius: Styles.radiusShell
    // "innerBModulesRadius" NÃO é declarado aqui: o mesmo token já existe mais
    // abaixo, na seção "Inner module sizes". Declarar os dois fazia o arquivo
    // inteiro do singleton falhar com "Duplicate property name" - e aí TODAS as
    // propriedades de Config (e do Colors, que depende delas) voltavam
    // "undefined" em todo módulo do Rumda.
    readonly property int barBorderWidth: 1

    // Animation sync
    readonly property int barsGrave: 1400
    readonly property int syncTbar: -(barsGrave - barMarginTop - barMarginBottom)
    readonly property int syncBbar: (barsGrave - barMarginTop - barMarginBottom)

    // Shadow Configuration
    readonly property bool enableBarShadow: false
    readonly property bool enableCatShadow: false
    readonly property int shadowOffsetX: 1
    readonly property int shadowOffsetY: 2

    // Dashboard Configuration
    readonly property int dashAnimDuration: 250
    // Tamanho do card do Dashboard, em PIXELS. Estava 3.36/3.6 aqui (alguém
    // copiou a proporção em vez do valor) - o card do Rumda media 3px.
    readonly property int dashboardWidth: 790
    readonly property int dashboardHeight: 485
    readonly property double dashTopRowRatio: 0.6
    readonly property int dashRadius: Styles.radiusShell
    readonly property int dashBorderWidth: 3
    // Borda dos módulos/botões do card. No Rumda era 0 (lá o comentário era
    // "me when long names"), então nenhum botão tinha contorno; 1px na cor de
    // borda do tema é o mesmo que o resto dos módulos do shell usa.
    readonly property int dashInnerModuleBorderWidth: 1
    readonly property int dashInnerModuleRadius: Styles.radiusShell
    readonly property int dashInnerPadding: 10
    readonly property int commitSquareSize: 12
    readonly property bool dashContribToolTip: true
    readonly property bool enableDashShadow: true
    readonly property int dashShadowOffsetX: 3
    readonly property int dashShadowOffsetY: 3

    // Inner module sizes
    readonly property int innerBModulesRadius: Styles.radiusButton
    readonly property int moduleSize: 28
    readonly property int moduleRadius: Styles.radiusButton
    readonly property int moduleBorderWidth: 1
    readonly property int innerModulesRadius: Styles.radiusButton

    // Notification settings
    readonly property int notifImageMaxHeight: 60
    readonly property int notifShotHeight: 100
    readonly property bool notifDynamicWidth: false
    readonly property int notifMinWidth: 220
    readonly property int notifWidth: 360
    readonly property int notifTimeout: 10000
    readonly property int notifIconSize: 56
    readonly property int notifButtonHeight: 22
    readonly property int notifSlideDuration: 250
    readonly property int notifBarHeight: 3
    readonly property int notifBarTopMargin: 8
    readonly property int notifShadowOffsetX: 9
    readonly property int notifShadowOffsetY: 8
    readonly property int notifRadius: 0
    readonly property int notifBorderWidth: 1
    readonly property int notifMarginTop: 20
    readonly property int notifMarginRight: 15
    readonly property int notifSpacing: 10
    readonly property int notifPadding: 12
    readonly property int notifMaxVisible: 5
    readonly property string notifFont: "JetBrainsMono Nerd Font"

    // Popout volume
    readonly property int popoutVolShadowOffsetX: 0
    readonly property int popoutVolShadowOffsetY: 0

    // Spotlight/zoom (Modules/Dashboard/RumdaDashboard/Zoom.qml) - o spotlight
    // que o Hyprland mostra quando o mouse fica parado sobre o desktop.
    property real zoomHoleRadius: 150
    property real zoomMinRadius: 30
    property real zoomMaxRadius: 600
    property real zoomRadiusStep: 20
    property real zoomDarkness: 0.8
    property real zoomFeather: 0.2
    property real zoomMin: 1.0
    property real zoomMax: 8.0
    property real zoomStep: 0.4

    // Usuário do GitHub do gráfico de contribuições (ContribGraph.qml).
    // No Rumda vinha de "Common.cGithubUsername" (fixo no config deles, com um
    // comentário "if you aren't me, change this"). O dado vem de
    // github-contributions-api.jogruber.de - serviço de terceiro - uma vez na
    // carga do shell e uma vez por hora. Vazio = sem fetch, sem requisição.
    readonly property string githubUsername: "wellington0dev"

    // Cat Configuration (opcional)
    property bool enableCat: false
    readonly property string catIconPath: ""
    readonly property int catMarginTop: 0
    readonly property int catMarginLeft: 0
    readonly property int catWidth: 50
    readonly property int catHeight: 90
}