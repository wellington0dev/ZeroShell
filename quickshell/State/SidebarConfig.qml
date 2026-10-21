pragma Singleton

import Quickshell
import Quickshell.Io

// Quais itens aparecem na sidebar - editável em Configurações > aba
// "sidebar" (Modules/Settings/SidebarPage.qml). Persistido em
// State/sidebar-config.json, igual ao padrão usado em CaptureService.
Singleton {
    id: root

    property bool showProfile: adapter.showProfile
    property bool showLauncher: adapter.showLauncher
    property bool showWorkspaces: adapter.showWorkspaces
    property bool showAppTray: adapter.showAppTray
    property bool showClock: adapter.showClock
    property bool showBattery: adapter.showBattery
    property bool showWifi: adapter.showWifi
    property bool showBluetooth: adapter.showBluetooth
    property bool showCapture: adapter.showCapture
    property bool showSettings: adapter.showSettings
    property bool showPower: adapter.showPower
    property bool showVolume: adapter.showVolume
    property bool showCpu: adapter.showCpu
    property bool showTheme: adapter.showTheme

    // ---- Onde a barra fica na tela ----
    // Uma barra só por vez:
    //   "left" / "right" -> barra VERTICAL colada na lateral
    //   "top"  / "bottom" -> barra HORIZONTAL colada na borda
    //
    // "left" é o padrão (como o shell sempre esteve). Os dois lados da barra
    // horizontal usam o mesmo conteúdo, só muda a borda onde ela encosta.
    readonly property var positions: [
        { value: "left", label: "Esquerda" },
        { value: "right", label: "Direita" },
        { value: "top", label: "Topo" },
        { value: "bottom", label: "Rodapé" }
    ]

    readonly property string position: adapter.position
    readonly property bool horizontal: position === "top" || position === "bottom"
    readonly property bool atRight: position === "right"

    function setPosition(value) {
        adapter.position = value
        file.writeAdapter()
    }

    function set(key, value) {
        adapter[key] = value
        file.writeAdapter()
    }

    // ---- Em qual terço da coluna cada item aparece: "top"/"center"/"bottom" ----
    // Não é posição exata, é o GRUPO (a barra desenha 3 blocos separados por 2
    // espaçadores elásticos, igual os Workspaces sempre usaram pra ficar no
    // centro - agora qualquer item pode ir pra lá). Na barra vertical é
    // topo/centro/rodapé; na horizontal, esquerda/centro/direita.
    // Dentro do mesmo grupo os itens mantêm a ordem "natural" (a ordem em
    // que aparecem no array de builtins do Sidebar.qml), não a ordem que o
    // usuário clicou.
    //
    // "id" aqui é a chave curta do item (ver defaultAlign).
    //.defaultAlign reorganizado na Fase 4 para espelhar as três seções da
    // barra vertical do Rumda (que NÃO tem sidebar: a dele é uma barra
    // horizontal em três seções - superior relógio/volume/CPU-RAM, central
    // workspaces, inferior tema/clima/internet/energia):
    //
    //   top    = clock, volume, cpu        (os "indicadores do sistema")
    //   center = workspaces
    //   bottom = o resto
    //
    // O que mudou em relação ao default anterior:
    //   - clock saiu de "bottom" e foi pra "top" (era o que o Rumda põe no
    //     alto, e é leitura rápida);
    //   - profile e launcher saíram de "top": no Rumda não existem, e eles
    //     disputavam espaço com os indicadores no alto;
    //   - appTray saiu de "bottom" e foi pra "bottom" AO LADO de launcher
    //     (era o lugar de item de fundo, não de indicador - ver SidebarPage,
    //     que reordena por ▲▼ dentro do mesmo grupo);
    //   - volume e cpu são novos (Fase 4).
    //
    // IMPORTANTE: isto é só o DEFAULT. O que o usuário salvou em
    // State/sidebar-config.json (campo "itemAlign") continua manda - o
    // getAlign() abaixo prefere o valor salvo e só cai no default quando não
    // há escolha salva. Ou seja, quem já tinha mudado algo continua com a
    // escolha antiga, e a mudança só vale para itens sem override.
    readonly property var defaultAlign: ({
        // top - perfil e indicadores do sistema
        profile: "top",
        clock: "top",
        volume: "top",
        cpu: "top",
        // center - navegação
        workspaces: "center",
        // bottom - ações e acessos
        launcher: "bottom",
        appTray: "bottom",
        wifi: "bottom",
        bluetooth: "bottom",
        battery: "bottom",
        capture: "bottom",
        settings: "bottom",
        power: "bottom",
        theme: "bottom"
    })

    property var itemAlign: adapter.itemAlign

    function getAlign(id) {
        const entry = itemAlign.find(o => o.id === id)
        if (entry) return entry.align
        return root.defaultAlign[id] || "bottom"
    }

    function setAlign(id, value) {
        const rest = adapter.itemAlign.filter(o => o.id !== id)
        adapter.itemAlign = [...rest, { id: id, align: value }]
        file.writeAdapter()
    }

    // ---- Ordem de cada item DENTRO do seu grupo (topo/centro/rodapé) ----
    // Número só serve pra ordenar (sort) os itens de um mesmo grupo entre
    // si - não precisa ser sequencial nem sem buracos, só a ordem relativa
    // importa. Trocado pelos botões "▲"/"▼" na aba Sidebar das
    // Configurações (Modules/Settings/SidebarPage.qml), que só reordenam
    // dentro do MESMO grupo (swap do valor com o vizinho).
    //
    // Sem valor salvo ainda, quem chama passa a posição "natural" do item
    // como "fallback" (índice no array combinado fixos+plugins - ver
    // Sidebar.qml/SidebarPage.qml), preservando a ordem original até o
    // usuário mexer pela primeira vez.
    property var itemOrder: adapter.itemOrder

    function getOrder(id, fallback) {
        const entry = itemOrder.find(o => o.id === id)
        return entry ? entry.order : (fallback ?? 0)
    }

    function setOrder(id, value) {
        const rest = adapter.itemOrder.filter(o => o.id !== id)
        adapter.itemOrder = [...rest, { id: id, order: value }]
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/State/sidebar-config.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property bool showProfile: true
            property bool showLauncher: true
            property bool showWorkspaces: true
            property bool showAppTray: true
            property bool showClock: true
            property bool showBattery: true
            property bool showWifi: true
            property bool showBluetooth: true
            property bool showCapture: true
            property bool showSettings: true
            property bool showPower: true
            // Fase 4: volume e CPU/RAM entram como itens opt-in, mas com
            // default true - sao indicadores de sistema sempre uteis, e o
            // usuario pode desligar cada um pela aba Sidebar das
            // Configuracoes sem tocar neste arquivo.
            property bool showVolume: true
            property bool showCpu: true
            property var itemAlign: []
            property var itemOrder: []
            // Fase 5: theme switch na sidebar
            property bool showTheme: true
            property string position: "left"
        }
    }
}
