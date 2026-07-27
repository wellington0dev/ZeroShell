pragma Singleton

import QtQuick
import Quickshell

// Resolve o nome de um ícone (ex.: "gear") pro caminho do arquivo SVG dentro
// desta mesma pasta (ex.: "file:///.../Icons/gear.svg"). Usado pelo
// Widgets/Icon.qml.
//
// "Qt.resolvedUrl(".")" pega a URL do DIRETÓRIO deste próprio arquivo - assim
// o caminho funciona não importa onde o usuário instalou o shell (não tem
// caminho absoluto fixo tipo "/home/weber/..." aqui dentro).
Singleton {
    readonly property url baseUrl: Qt.resolvedUrl(".")

    function path(name) {
        return baseUrl + name + ".svg"
    }
}
