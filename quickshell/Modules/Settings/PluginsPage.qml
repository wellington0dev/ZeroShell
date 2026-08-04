import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Theme
import qs.Widgets
import qs.Modules.Plugins

// Aba "Plugins" das Configurações - lista o que tá instalado em
// ~/.config/quickshell/plugins/<id>/ (PluginService.qml faz a descoberta de
// verdade), com um switch de ligar/desligar por plugin, um botão "play"
// pra rodar o "testScript" do manifesto (se declarado - ver
// PluginService.qml) e, se o plugin declarar "settingsPage", um botão pra
// abrir a página de configuração própria dele.
Item {
    id: root

    property string expandedId: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: Styles.spacing * 1.5

        RowLayout {
            Layout.fillWidth: true
            spacing: Styles.spacing

            Text {
                text: "Plugins"
                color: Styles.foreground
                font.pixelSize: 16
                font.family: Styles.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                id: rescanButton
                text: "Atualizar"
                onClicked: PluginService.rescan()

                Connections {
                    target: PluginService
                    function onRescanFinished() { rescanButton.flashSuccess() }
                }
            }
        }

        Text {
            text: "Instalados em ~/.config/quickshell/plugins/<id>/, cada um com um plugin.json. Depois de instalar ou remover um, clique em \"Atualizar\"."
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Text {
            visible: PluginService.plugins.length === 0
            text: "Nenhum plugin instalado."
            color: Styles.foregroundMuted
            font.pixelSize: Styles.fontSizeSmall
            font.family: Styles.fontFamily
            Layout.topMargin: Styles.spacing * 2
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: PluginService.plugins.length > 0
            clip: true
            spacing: Styles.spacing
            model: PluginService.plugins

            delegate: ColumnLayout {
                id: card

                required property var modelData

                // Estado do último "testScript" rodado nesta sessão -
                // não é persistido, some se reabrir as Configurações.
                property string testState: "idle" // idle | running | ok | fail
                property string testOutput: ""

                width: ListView.view.width
                spacing: 0

                Process {
                    id: testProcess
                    command: ["bash", card.modelData.dir + "/" + (card.modelData.testScript || "")]
                    stdout: StdioCollector { id: testStdout }
                    stderr: StdioCollector { id: testStderr }
                    onExited: (exitCode) => {
                        card.testState = exitCode === 0 ? "ok" : "fail"
                        card.testOutput = (testStdout.text + testStderr.text).trim()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: content.implicitHeight + Styles.spacing * 2
                    radius: Styles.radiusShell
                    color: Styles.surface

                    ColumnLayout {
                        id: content

                        anchors.fill: parent
                        anchors.margins: Styles.spacing
                        spacing: Styles.spacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Styles.spacing

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 6

                                    Text {
                                        text: card.modelData.name || card.modelData.id
                                        color: Styles.foreground
                                        font.pixelSize: Styles.fontSizeNormal
                                        font.family: Styles.fontFamily
                                        font.bold: true
                                    }

                                    Text {
                                        visible: !!card.modelData.version
                                        text: card.modelData.version ? ("v" + card.modelData.version) : ""
                                        color: Styles.foregroundMuted
                                        font.pixelSize: Styles.fontSizeSmall
                                        font.family: Styles.fontFamily
                                    }
                                }

                                Text {
                                    visible: !!card.modelData.description
                                    text: card.modelData.description || ""
                                    color: Styles.foregroundMuted
                                    font.pixelSize: Styles.fontSizeSmall
                                    font.family: Styles.fontFamily
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                visible: card.testState === "ok" || card.testState === "fail"
                                text: card.testState === "ok" ? "✓" : "✗"
                                color: card.testState === "ok" ? Styles.success : Styles.danger
                                font.pixelSize: Styles.fontSizeNormal
                                font.family: Styles.fontFamily
                                font.bold: true
                            }

                            IconButton {
                                visible: !!card.modelData.testScript
                                icon: "play"
                                size: 22
                                enabled: card.modelData.enabled && card.testState !== "running"
                                onClicked: {
                                    card.testState = "running"
                                    card.testOutput = ""
                                    testProcess.running = true
                                }
                            }

                            IconButton {
                                visible: !!card.modelData.settingsPage
                                icon: "gear"
                                size: 22
                                active: root.expandedId === card.modelData.id
                                enabled: card.modelData.enabled
                                onClicked: root.expandedId = (root.expandedId === card.modelData.id ? "" : card.modelData.id)
                            }

                            Switch {
                                checked: card.modelData.enabled
                                onToggled: PluginService.setEnabled(card.modelData.id, !card.modelData.enabled)
                            }
                        }

                        Text {
                            visible: card.testState === "fail" && !!card.testOutput
                            text: card.testOutput
                            color: Styles.danger
                            font.pixelSize: Styles.fontSizeSmall
                            font.family: Styles.fontFamily
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        // Separador só quando a página própria do plugin tá
                        // expandida - sem isso ela ficava colada direto no
                        // cabeçalho do card, sem nenhuma quebra visual.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.topMargin: 2
                            visible: settingsLoader.active
                            color: Styles.border
                        }

                        // Página de configuração própria do plugin - só
                        // carregada (Loader "active") quando expandida, pra
                        // não instanciar QML de todo plugin instalado o
                        // tempo todo à toa.
                        //
                        // "Layout.preferredHeight: active ? implicitHeight : 0"
                        // é necessário, não decorativo: sem isso, medido ao
                        // vivo (console.log), o ColumnLayout "content" ficava
                        // com implicitHeight TRAVADO no valor de quando
                        // estava expandido mesmo depois do Loader desativar
                        // (o Loader não reavisa implicitHeight=0 sozinho pro
                        // ColumnLayout pai quando o item interno morre) - o
                        // card nunca encolhia de volta ao fechar. Forçando
                        // explicitamente aqui garante o valor certo nos dois
                        // sentidos.
                        Loader {
                            id: settingsLoader
                            Layout.fillWidth: true
                            Layout.preferredHeight: active ? implicitHeight : 0
                            active: root.expandedId === card.modelData.id && card.modelData.enabled
                            source: active ? ("file://" + card.modelData.dir + "/" + card.modelData.settingsPage) : ""
                        }
                    }
                }
            }
        }
    }
}
