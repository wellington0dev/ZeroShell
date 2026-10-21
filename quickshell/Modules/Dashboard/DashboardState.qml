pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Estado compartilhado do Dashboard.
//
// HISTÓRICO (Fase 3): este singleton existia para mediar entre DUAS
// PanelWindow - a DashboardTrigger.qml (faixa de 10px no topo que detectava
// hover) e a DashboardWindow.qml (o card). Como não dá pra uma referenciar a
// outra, cada uma dizia aqui se o mouse estava em cima e "open" combinava os
// dois sinais, com um closeTimer de 200ms pra não fechar na hora em que o
// mouse saía da faixa e ainda não tinha "chegado" no card.
//
// Na Fase 3 o gatilho de hover foi removido (a abertura passa a ser por
// atalho - Super+TAB - e a janela virou WlrLayershell com foco exclusivo de
// teclado, o que não se combina com uma faixa de hover no topo da tela). Com o
// hover fora, os dois sinais e o closeTimer não têm mais de quem mediar: eles
// viravam um segundo dono do estado "open", capaz de brigar com a abertura por
// atalho e deixar o painel preso. Por isso saíram.
//
// O que SOBROU é o essencial e não pode quebrar:
//
//   - "open"        : único dono do estado, só mudado pelo IpcHandler/ESC/
//                     clique-fora. Sem timer competindo, não há como travar.
//
//   - "currentTab"  : mora aqui (e não na aba) para permitir troca externa via
//                     IPC - hypr/scripts/debug-shell.sh e debug-shell-video.sh
//                     abrem o Dashboard já numa aba específica.
//
//   - IpcHandler    : é o ÚNICO caminho de escrita de "open" e a superfície
//                     pública que os scripts já usam. Intocado, inclusive o
//                     "toggle" (é ele que o atalho Super+TAB vai chamar):
//                         qs -c ~/.config/quickshell ipc call dashboard toggle
//
// Note que o RPC do IpcHandler é "toggle/open/close" e NÃO precisa de
//hyprctl reload nem de nada no Hyprland - quem registra o atalho é
// Configurações > Atalhos (State/KeybindConfig.qml -> sync-hypr-keybinds.sh),
// fora do escopo desta fase.
Singleton {
    id: root

    // Largura do card (DashboardWindow.qml). Mantida aqui porque a DashboardWindow
    // é quem a usa hoje; o gatilho de hover que também usava foi removido.
    readonly property int cardWidth: 560

    // Aberto/fechado. Única fonte da verdade.
    //
    // NÃO existe mais "hoveringTrigger"/"hoveringCard"/"wantsOpen"/closeTimer
    // aqui: com a abertura por atalho, qualquer temporizador aqui seria um
    // segundo dono do estado, capaz de reabrir/fechar o painel contra a
    // vontade do usuário (a falha clássica do "preso aberto" ou "preso
    // fechado"). A animação de entrada/saída já tem o tempo dela no
    // PanelAnim (Widgets/PanelAnim.qml), que cuida do "esconder a superfície
    // depois da animação" - não precisa de timer de estado aqui.
    //
    // "open" é espelhado em disco (State/dashboard-open.json) para sobreviver
    // ao hot reload: o shell recarrega sozinho quando qualquer QML muda, e o
    // singleton é recriado do zero - então o painel voltava a "fechado" no meio
    // da edição, o que dava a impressão de que o reload não tinha funcionado.
    // Guardar em disco faz ele voltar sozinho, que é o que se quer enquanto se
    // mexe no visual dele.
    //
    // Continua sendo um estado normal (nenhum timer, nenhuma segunda
    // donicidade): a única diferença é que o valor inicial vem do arquivo em
    // vez de ser false.
    property bool open: openAdapter.value

    function setOpen(value: bool): void {
        openAdapter.value = value
        openFile.writeAdapter()
    }

    FileView {
        id: openFile
        // "watchChanges" desligado de propósito: quem escreve este arquivo é
        // o próprio singleton (setOpen), e reagir à própria escrita só
        // causaria trabalho inútil - o valor já está no memória.
        path: Quickshell.statePath("dashboard-open.json")
        watchChanges: false

        JsonAdapter {
            id: openAdapter
            property bool value: false
        }
    }

    // Aba ativa (DashboardTabs.qml). Ver comentário acima: fica neste singleton
    // pra ser trocável de fora via IPC.
    property string currentTab: "home"

    IpcHandler {
        target: "dashboard"

        // Nomeadas igual às outras janelas (open/close, além do toggle) por
        // consistência - "root.open =" aqui aponta pra property acima, sem
        // ambiguidade (função e property vivem em objetos diferentes).
        function toggle(): void {
            root.setOpen(!root.open)
        }
        function open(): void { root.setOpen(true) }
        function close(): void { root.setOpen(false) }

        // Troca a aba ativa - "home", "player", "system" ou "quick" (ver
        // Modules/Dashboard/DashboardTabs.qml). Não valida o nome: um valor
        // inválido só faz o Loader do DashboardWindow.qml cair no "default"
        // (aba "home"), sem quebrar nada.
        function tab(name: string): void { root.currentTab = name }
    }
}