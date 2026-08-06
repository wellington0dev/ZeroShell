import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Theme
import qs.State

// Renderiza o wallpaper - substitui o awww (cliente Wayland externo, fork do
// swww). O motivo de trazer isso pra dentro do quickshell: nenhum cliente
// Wayland consegue "ler" a superfície de outro por questão de segurança do
// protocolo, então enquanto o awww desenhava o wallpaper, não tinha como
// nenhum painel nosso (ex.: a borda da tela) refletir esse conteúdo de
// verdade - só dava pra fazer uma cópia independente da mesma imagem-fonte.
// Com o quickshell desenhando, a imagem é só mais um Item na nossa árvore:
// dá pra recortar com cantos arredondados de verdade, alinhados com o resto
// do shell.
//
// matugen + extract-colors.py (hypr/scripts/apply-theme.sh) continuam do
// jeito que estão - só a EXIBIÇÃO da imagem muda, não a extração de cor.
PanelWindow {
    id: root

    // Cobre a tela inteira, decorativo (não reserva espaço) e não some
    // atrás de fullscreen - "Background" é a camada mais baixa do
    // layer-shell (oposto do "Overlay" que os painéis flutuantes usam), pra
    // continuar se comportando como um wallpaper de verdade (janelas
    // normais cobrem ele, painéis do shell cobrem ele).
    //
    // "color: Styles.background" (não "transparent") - com
    // WallpaperConfig.margin > 0 sobra um vão entre o recorte arredondado
    // (canvas, abaixo) e a borda de verdade da tela; sem uma cor de fundo
    // aqui esse vão ficaria preto (nada desenhado, mostra o fundo cru do
    // compositor). Com margin 0 (padrão) isso nunca aparece - o canvas cobre
    // a janela inteira.
    visible: true
    color: Styles.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Sem isto a janela (tela inteira) roubaria clique de tudo que
    // estivesse "atrás" dela - que aqui é literalmente tudo, já que essa é
    // a camada mais baixa.
    mask: Region {}

    FileView {
        id: wallpaperPathFile
        path: Quickshell.env("HOME") + "/.cache/hypr/wallpaper_current"
        // Sem isto o FileView leria o caminho só uma vez, na subida do
        // shell - trocar de wallpaper depois (toggle-wallpaper.sh,
        // WallpaperGrid.qml, keybind SUPER+W) nunca apareceria aqui. Mesmo
        // padrão já usado em LockScreen.qml e WallpaperGrid.qml pro mesmo
        // arquivo.
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string wallpaperPath: (wallpaperPathFile.text() || "").trim()
    readonly property string wallpaperSource: wallpaperPath ? "file://" + wallpaperPath : ""

    // A imagem recua "WallpaperConfig.margin" dos 4 lados e ganha cantos
    // arredondados por "WallpaperConfig.radius" - editável em Configurações,
    // categoria de wallpaper (Modules/Settings/WallpaperGrid.qml). Sidebar/
    // Dock/Dashboard/Volume/Menu de energia não entram nessa conta: são só
    // painéis flutuando por cima (cada um com a própria sombra revelando o
    // wallpaper ao redor normalmente).
    // ClippingRectangle (não Rectangle comum) de propósito: um Rectangle
    // com "clip: true" só recorta os filhos num retângulo RETO (o "radius"
    // dele arredonda a própria borda/preenchimento, mas não vira máscara
    // pros filhos) - testado ao vivo, com Rectangle simples as Images
    // continuavam quadradas até o pixel real, sem arredondar nada. Mesma
    // técnica já usada no thumbnail do wallpaper na lockscreen (ver
    // Modules/Lock/LockScreen.qml).
    ClippingRectangle {
        id: canvas

        x: WallpaperConfig.margin
        y: WallpaperConfig.margin
        width: root.width - WallpaperConfig.margin * 2
        height: root.height - WallpaperConfig.margin * 2
        color: "transparent"
        radius: WallpaperConfig.radius

        // Crossfade entre wallpapers: o awww fazia uma transição "wipe"; sem
        // ele, uma troca seca de "source" ficaria brusca demais. Duas
        // Images alternando qual fica "por cima" (opacity 1) resolve -
        // trocar url. "showA" decide quem tá visível agora; a troca sempre
        // escreve na que está ESCONDIDA e só promove ela a visível quando
        // termina de carregar (onStatusChanged), pra não piscar um frame
        // vazio caso a imagem demore a decodificar.
        property bool showA: true

        Image {
            id: imgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: canvas.showA ? 1 : 0
            onStatusChanged: if (status === Image.Ready) canvas.showA = true

            Behavior on opacity {
                NumberAnimation { duration: Motion.durationSlow }
            }
        }

        Image {
            id: imgB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: canvas.showA ? 0 : 1
            onStatusChanged: if (status === Image.Ready) canvas.showA = false

            Behavior on opacity {
                NumberAnimation { duration: Motion.durationSlow }
            }
        }
    }

    // Primeira carga: escreve direto na camada A, sem passar pelo troca-e-
    // -anima de onWallpaperPathChanged (senão a tela começaria transparente
    // e "surgiria" com fade, em vez de já aparecer pronta na subida do
    // shell).
    Component.onCompleted: imgA.source = wallpaperSource

    // Troca de wallpaper depois disso: escreve sempre na Image escondida no
    // momento (a visível seguiria mostrando o wallpaper ANTERIOR até a nova
    // terminar de carregar e a Behavior on opacity cruzar as duas).
    onWallpaperSourceChanged: {
        if (canvas.showA) imgB.source = wallpaperSource
        else imgA.source = wallpaperSource
    }
}
