import qs.Widgets

// Um IconButton especializado pra apps do AppTray: some quando o app não
// está rodando ("toplevel: null"), mostra o logo colorido de verdade em vez
// de tingir com a cor do tema ("monochrome: false", já que são marcas
// reconhecíveis - Spotify verde, Discord roxo etc.), e clicar foca a janela
// da aplicação (traz pra frente) em vez de abrir um painel do shell.
IconButton {
    id: root

    property var toplevel: null

    // 32 e não o 36 padrão do IconButton: a coluna útil da sidebar tem 40px
    // (shellWidth 56 - 2*Styles.spacing) e o tile do SidebarItem ainda tem
    // respiro - 36 + 2*4 já passaria da borda.
    size: 32

    visible: toplevel !== null
    monochrome: false
    onClicked: if (root.toplevel) root.toplevel.activate()
}
