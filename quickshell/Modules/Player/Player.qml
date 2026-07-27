pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Explicit pick from the player switcher; falls back to auto-selection
    // below whenever it's null or the picked player disappears.
    property MprisPlayer manualSelection: null

    readonly property var players: Mpris.players.values

    readonly property MprisPlayer active: {
        if (manualSelection && players.includes(manualSelection)) return manualSelection
        const playing = players.find(p => p.isPlaying)
        if (playing) return playing
        return players.length > 0 ? players[0] : null
    }

    function select(player) {
        manualSelection = player
    }
}
