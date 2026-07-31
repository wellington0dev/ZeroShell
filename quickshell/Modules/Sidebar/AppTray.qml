import QtQuick
import Quickshell.Wayland
import qs.Theme

// Atalhos pra Spotify/Discord/Steam - só aparecem (via AppButton.visible)
// quando o respectivo app está de fato rodando, mesmo minimizado/em segundo
// plano. Clicar foca a janela do app.
Column {
    id: root

    spacing: Styles.spacing

    // Snapshot reativo de toda janela que o Hyprland expõe pelo protocolo
    // wlr-foreign-toplevel - isso inclui janelas minimizadas/em segundo
    // plano, que é como detectamos "o app está rodando" sem precisar que a
    // janela esteja focada ou visível.
    readonly property var toplevels: ToplevelManager.toplevels.values

    // Procura por appId que contenha o texto dado (não é comparação exata)
    // porque o mesmo app pode ter appId diferente dependendo de como foi
    // instalado - ex.: Spotify nativo usa "spotify", mas a versão Flatpak
    // usa algo como "com.spotify.Client". "includes" pega os dois.
    function findToplevel(needle) {
        return toplevels.find(t => t.appId && t.appId.toLowerCase().includes(needle)) ?? null
    }

    AppButton {
        icon: "spotify"
        toplevel: root.findToplevel("spotify")
    }

    AppButton {
        icon: "discord"
        toplevel: root.findToplevel("discord")
    }

    AppButton {
        icon: "steam"
        toplevel: root.findToplevel("steam")
    }
}
