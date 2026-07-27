import QtQuick
import Quickshell

// Faixa invisível de 10px colada no topo da tela, sempre presente. Só existe
// pra detectar quando o mouse passa por ali - ao contrário do
// DashboardWindow (que fica fora da tela quando fechado), essa aqui nunca se
// move, então precisa ser bem fina pra não atrapalhar cliques em outras
// janelas encostadas no topo.
PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 10

    HoverHandler {
        onHoveredChanged: DashboardState.hoveringTrigger = hovered
    }
}
