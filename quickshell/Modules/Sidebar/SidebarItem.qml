import QtQuick
import qs.Theme

// SidebarItem: container visual no estilo Rumda para cada item da sidebar.
// Envolve o conteúdo num Rectangle com fundo surface, borda border, radiusSmall,
// e padding interno. Mantém o conteúdo centralizado (horizontal e vertical).
//
// Uso: SidebarItem { content: MeuComponente {} }
Rectangle {
    id: container

    // Padding: "tight" reduz o respiro vertical (itens que já têm altura
    // própria, como o Workspaces). O valor é metade do "spacing" porque o tile
    // precisa caber na coluna de 40px da sidebar (shellWidth 56 - 2*spacing):
    // com 8px de cada lado um botão de 32px não caberia, e o tile inteiro
    // ficava visualmente "fofo" (32 de botão dentro de 40 de coluna com um
    // respiro enorme). Com 4 o botão de 32 preenche um quadrado de 40x40.
    property bool tight: false

    readonly property real padding: Styles.spacing / 2

    // Conteúdo sem tamanho nenhum (ex.: AppTray com nenhum app rodando) não
    // deve sobrar um quadradinho vazio no meio da sidebar - o item inteiro
    // colapsa e o espaço some.
    readonly property bool hasContent: contentLoader.implicitWidth > 0 || contentLoader.implicitHeight > 0

    // O tile ocupa a largura inteira da coluna da sidebar (o Loader delegate
    // usa Layout.fillWidth) e o conteúdo fica centralizado dentro - é o que
    // impede um botão maior que a coluna de vazar pra fora da sidebar.
    width: parent.width
    implicitWidth: hasContent ? contentLoader.implicitWidth + padding * 2 : 0
    implicitHeight: hasContent ? contentLoader.implicitHeight + (tight ? padding : padding * 2) : 0
    visible: hasContent

    radius: Styles.radiusSmall
    color: hover.hovered ? Styles.surfaceAlt : Styles.surface
    border.color: hover.hovered ? Styles.accent : Styles.border
    border.width: 1

    HoverHandler { id: hover }
    Behavior on color {
        ColorAnimation { duration: Motion.durationFast; easing.type: Easing.OutQuad }
    }
    Behavior on border.color {
        ColorAnimation { duration: Motion.durationFast; easing.type: Easing.OutQuad }
    }

    // Conteúdo instanciado de "content" (um Component) por um Loader
    // centralizado. O Loader repassa o implicitWidth/implicitHeight do item
    // carregado, que é o que dá o tamanho do container acima - por isso todo
    // conteúdo precisa ter tamanho próprio (Column/ColumnLayout na raiz), e não
    // um Item com "anchors.fill".
    Loader {
        id: contentLoader
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // Teto de largura: conteúdo mais largo que o espaço útil do tile é
        // espremido (o Loader também redimensiona o item carregado), então ele
        // nunca vaza pra fora da sidebar.
        width: Math.min(implicitWidth, Math.max(0, container.width - padding * 2))
        sourceComponent: container.content
    }

    // Property para receber o conteúdo (SidebarItem { content: MeuComponente {} })
    // Sem inicializador explícito: "undefined" numa property Component dispara
    // "Unable to assign [undefined] to QQmlComponent*" - o padrão já é null,
    // que o Loader trata igual a "sem conteúdo".
    property Component content
}