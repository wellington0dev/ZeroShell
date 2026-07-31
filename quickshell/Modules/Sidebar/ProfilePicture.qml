import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Theme

// Avatar circular no topo da sidebar. Mostra ~/.face (o arquivo de foto de
// perfil padrão do freedesktop, usado por telas de login/greeters também) e
// permite trocar a foto clicando nela.
//
// "ClippingRectangle" é um componente do Quickshell que recorta qualquer
// conteúdo (a Image, aqui) na forma do retângulo - com "radius: width/2" isso
// vira um círculo perfeito, senão a imagem apareceria quadrada por cima do
// fundo arredondado.
ClippingRectangle {
    id: root

    readonly property string facePath: Quickshell.env("HOME") + "/.face"

    // 40 é o tamanho usado na sidebar; a aba Início do Dashboard usa um
    // valor maior (ver HomeTab.qml).
    property int size: 40

    implicitWidth: size
    implicitHeight: size
    radius: width / 2
    color: Styles.surfaceAlt
    border.color: Styles.border
    border.width: 1

    Image {
        id: avatar

        // Qt cacheia imagens locais pelo caminho do arquivo; como o caminho
        // (~/.face) nunca muda mesmo depois de trocar a foto, sem esse
        // truque a imagem antiga continuaria aparecendo. Incrementar
        // "reloadToken" muda a URL (via "?r=N"), forçando um recarregamento.
        property int reloadToken: 0

        anchors.fill: parent
        source: "file://" + root.facePath + "?r=" + reloadToken
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: false
    }

    // Escurece a foto no hover, sinalizando "isso é clicável".
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "#000000"
        opacity: hover.hovered ? 0.35 : 0

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: filePicker.open() }

    // Ao clicar na foto, abre o seletor de arquivos nativo do Qt pra escolher
    // uma imagem nova.
    FileDialog {
        id: filePicker

        title: "Escolher foto de perfil"
        currentFolder: "file://" + Quickshell.env("HOME")
        nameFilters: [
            "Imagens (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.svg)",
            "Todos os arquivos (*)"
        ]

        onAccepted: copyProcess.run(selectedFile)
    }

    // Copia o arquivo escolhido por cima de ~/.face via "cp" (mais simples e
    // seguro que reimplementar cópia de arquivo binário em QML/JS) e força o
    // Image acima a recarregar quando terminar com sucesso.
    Process {
        id: copyProcess

        function run(url) {
            const path = decodeURIComponent(url.toString().replace("file://", ""))
            command = ["cp", path, root.facePath]
            running = true
        }

        onExited: (exitCode) => {
            if (exitCode === 0) avatar.reloadToken++
        }
    }
}
