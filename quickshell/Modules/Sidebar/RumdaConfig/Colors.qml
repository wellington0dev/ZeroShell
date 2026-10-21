pragma Singleton

import Quickshell
import QtQuick
import qs.Theme

// Cores dos módulos portados do Rumda.
//
// ESTE ARQUIVO É A ADAPTAÇÃO, NÃO UMA CÓPIA: cada nome do Rumda
// (backgroundColor, moduleBG, accentColor...) aponta pro token vivo do shell
// (Styles.background, Styles.surface, Styles.accent...), que vem de
// State/colors.json e é regerado pelo matugen a cada troca de wallpaper ou de
// claro/escuro. Antes these eram "#1c1612"/"#3A2D22"/... literais fixos, então a
// SidebarNew ficava ALWAYS marrom-escuro, sem responder ao tema (e sem
// conseguir nem carregar: "Colors" não estava no qmldir do RumdaConfig, e cada
// módulo logava "ReferenceError: Colors is not defined").
//
// A correspondência 1:1 com os nomes originais do Rumda está em cada linha,
// e a paleta literal que o Rumda usava (dark/light) continua disponível como
// token de referência em Theme/Styles.qml (rumdaDark*/rumdaLight*) caso um
// dia alguém quiser comparar.
Singleton {

  // ---- barra / superfícies ----
  property color backgroundColor: Styles.background     // <- backgroundColor (cor da barra)
  property color moduleBG: Styles.surface                // <- moduleBG
  property color borderColor: Styles.border              // <- borderColor

  // ---- destaques ----
  property color indicatorBGColor: Styles.accentAlt      // <- indicatorBGColor (anel/fundo do indicador)
  property color accentColor: Styles.accent               // <- accentColor
  property color accent2Color: Styles.accentAlt           // <- accent2Color
  property color gradientAccent2Color: Styles.accentAlt   // <- gradientAccent2Color (base/direita da barra de volume)
  property color errorColor: Styles.danger                // <- errorColor

  // A sombra do Rumda é a cor da borda com alfa (8 dígitos, ex.:
  // "#CC3A2D22") - mesma receita com o token do shell, onde as cores são
  // opacas e quem traz a transparência é o alfa.
  property color shadowColor: Qt.alpha(Styles.border, 0.8)

  // ---- dashboard ----
  property color dashBGColor: Styles.surfaceAlt           // <- dashBGColor
  property color dashModulesColor: Styles.surface         // <- dashModulesColor (módulos/retângulos internos)
  property color dashBorderColor: Styles.border           // <- dashBorderColor (bordas / círculo em volta do pfp)
  property color dashPFPColor: Styles.surfaceAlt          // <- dashPFPColor (círculo do pfp)

  // Botões (power) no Rumda usam o mesmo fundo do pfp.
  property color powerButtons: Styles.surfaceAlt          // <- powerButtons

  // ---- blocos de commit do dashboard (gráfico de contribuições) ----
  // Rampa de "calor" do heatmap. No Rumda eram 5 marrons fixos (#5c3d2d ->
  // #f7b292) que não tinham nada a ver com o tema - em qualquer wallpaper o
  // gráfico continuava marrom. Aqui o nível 0 (dia sem commit) é a cor neutra
  // de fundo e os níveis 1..4 são o accent do tema com intensidade
  // crescente, que é a mesma convenção do próprio GitHub.
  property color level0Contrib: Styles.surfaceAlt
  property color level1Contrib: Qt.alpha(Styles.accent, 0.35)
  property color level2Contrib: Qt.alpha(Styles.accent, 0.58)
  property color level3Contrib: Qt.alpha(Styles.accent, 0.78)
  property color level4Contrib: Styles.accent

  // O autor do Rumda marcou como "ignore this" nos dois arquivos. Aqui vira a
  // cor de DESTAQUE do tooltip de fundo do gráfico de contribuições - por isso
  // é uma superfície clara, não o accent (texto no accent não se lê).
  property color dashAccentColor: Styles.foreground
  property color tooltipTextColor: Styles.background
}