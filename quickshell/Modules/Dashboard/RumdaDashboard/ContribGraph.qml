import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Modules.Sidebar.RumdaConfig

Rectangle {
  id: contribGraphRect
  property string username: Config.githubUsername
  property var contributionData: [] // this is fetched, but organised chronologically, so we need to create the following bit..
  property var gridData: []  // < which is this. gotta organise them into weeks

  readonly property int headerMargin: 23

  // Sem usuário do GitHub configurado (RumdaConfig/Config.qml,
  // "githubUsername") não há o que buscar: o fetch do Rumda rodava a cada
  // carregamento do shell e logava "Failed to parse GitHub data" no console.
  // Com usuário vazio o gráfico fica só com o fundo - sem chamada de rede.
  readonly property bool enabled: username.length > 0

  // Limpa os dados quando o usuário muda.
  //
  // NÃO mexe em "githubFetch.running" direto aqui: no carregamento inicial este
  // handler roda ANTES de o binding de "enabled" ser reavaliado, então
  // "running" recebia false, quebrava o binding de "running" do próprio
  // Process - e o fetch nunca começava (o gráfico ficava vazio pra sempre,
  // sem erro nenhum). O "Qt.callLater" espera os bindings assentarem antes de
  // reiniciar o processo.
  // Distingue o primeiro "onUsernameChanged" (que vem junto com a criação do
  // componente, antes do Component.onCompleted) de uma troca de usuário de
  // verdade: no primeiro caso quem dispara o fetch é o próprio binding de
  // "running", e reiniciar aqui só matava a requisição que ele tinha acabado
  // de começar.
  property bool initialized: false

  Component.onCompleted: initialized = true

  onUsernameChanged: {
    contributionData = [];
    gridData = [];

    if (!initialized) return;

    Qt.callLater(() => {
      githubFetch.running = false;
      githubFetch.running = contribGraphRect.enabled;
    });
  }
  implicitWidth: {
    let weeks = Math.ceil(gridData.length / 7);
    return weeks * (Config.commitSquareSize + 3) + 44;
  }
  color: Colors.dashModulesColor
  border.width: Config.dashInnerModuleBorderWidth
  border.color: Colors.borderColor
  radius: Config.dashInnerModuleRadius

  Process {
    id: githubFetch

    // "-f" faz o curl falhar em erro HTTP em vez de salvar a página de erro
    // como se fosse JSON, e o "--max-time" é generoso de propósito: esse
    // serviço responde devagar (medido ~3s na primeira conexão, e passou de
    // 10s na carga do shell), então com 10s o gráfico ficava vazio sem erro
    // nenhum na tela.
    command: ["curl", "-s", "-f", "--max-time", "30", `https://github-contributions-api.jogruber.de/v4/${username}`]
    running: contribGraphRect.enabled

    // A resposta é um JSON de ~75KB em UMA linha. O SplitParser entrega o
    // stream em PEDAÇOS, e o "JSON.parse" de cada pedaço sempre falhava
    // ("Failed to parse GitHub data") - o gráfico ficava vazio pra sempre.
    // O StdioCollector junta tudo e o parse acontece no fim do stream, que é o
    // mesmo padrão do Modules/Capture/CaptureService.qml.
    stdout: StdioCollector {
      onStreamFinished: {
        let raw = this.text.trim();

        // Falha (rede, serviço fora, timeout) NÃO limpa o que já está na tela:
        // um horário de refresh perdido não pode apagar o gráfico inteiro.
        if (!raw.length) {
          console.warn("ContribGraph: resposta vazia - mantendo o gráfico anterior");
          return;
        }

        try {
          let response = JSON.parse(raw);

          let today = new Date();
          today.setHours(0, 0, 0, 0);

          let oneYearAgo = new Date(today);
          oneYearAgo.setFullYear(today.getFullYear() - 1);
          oneYearAgo.setHours(0, 0, 0, 0);

          contribGraphRect.contributionData = response.contributions.filter(day => {
            let parts = day.date.split('-');
            let dayDate = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));

            return dayDate >= oneYearAgo && dayDate <= today;
          });

          contribGraphRect.organizeGridData();
        } catch (e) {
          console.error("ContribGraph: não deu pra ler a resposta do GitHub:", e);
        }
      }
    }
  }

  function organizeGridData() {
    gridData = [];

    if (contributionData.length === 0)
      return;
    let sorted = contributionData.slice().sort((a, b) => {
      return new Date(a.date) - new Date(b.date);
    });

    const MAX_DAYS = 46 * 7;
    if (sorted.length > MAX_DAYS) {
      sorted = sorted.slice(sorted.length - MAX_DAYS);
    }

    gridData = sorted;
  }

  Timer {
    interval: 3600000
    running: true
    repeat: true
    onTriggered: githubFetch.running = true
  }

  Item {
    id: tooltipContainer
    anchors.fill: parent
    z: 1000

    Loader {
      id: tooltipLoader
      active: false

      sourceComponent: Rectangle {
        id: tooltip
        property var dayData: ({
            count: 0,
            date: ""
          })

        function updatePosition(square) {
          let pos = square.mapToItem(tooltipContainer, 0, 0);
          tooltip.x = pos.x + square.width / 2 - tooltip.width / 2;
          tooltip.y = pos.y - tooltip.height - 5;
        }

        width: tooltipText.width + 16
        height: tooltipText.height + 12
        color: Colors.dashAccentColor
        radius: 6
        border.color: Colors.borderColor
        border.width: 1

        Rectangle {
          width: 8
          height: 8
          color: Colors.dashAccentColor
          rotation: 45
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.bottom
          anchors.topMargin: -4
        }

        Text {
          id: tooltipText
          anchors.centerIn: parent
          text: dayData.count + " contributions\n" + dayData.date
          color: Colors.tooltipTextColor
          font.family: Styles.fontFamily
          font.pixelSize: Styles.fontSizeSmall
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 14
    anchors.bottomMargin: 13
    spacing: 4

    RowLayout {
      Layout.fillWidth: true

      Text {
        // Sem usuário configurado o título vira uma dica, em vez do
        // "@'s Contributions" sem nome que ficava antes.
        text: contribGraphRect.enabled ? `@${username}'s Contributions` : "Contribuições do GitHub"
        color: contribGraphRect.enabled ? Colors.accentColor : Styles.foregroundMuted
        font.family: Styles.fontFamily
        font.pixelSize: Styles.fontSizeSmall
        font.bold: true
        Layout.alignment: Qt.AlignBottom
        Layout.leftMargin: headerMargin
      }

      Item {
        Layout.fillWidth: true
      }

      Text {
        text: contributionData.length > 0 ? `${contributionData.reduce((sum, d) => sum + d.count, 0)} total` : ""
        color: Colors.accent2Color
        font.family: Styles.fontFamily
        font.pixelSize: Styles.fontSizeTitle
        font.bold: true
        Layout.rightMargin: headerMargin
        Layout.alignment: Qt.AlignBottom
      }
    }

    Grid {
      id: contributionGrid
      columns: Math.ceil(gridData.length / 7)
      rows: 7
      spacing: 3
      flow: Grid.TopToBottom
      Layout.alignment: Qt.AlignHCenter

      Repeater {
        model: gridData.length

        Rectangle {
          id: commitSquares
          width: Config.commitSquareSize
          height: Config.commitSquareSize
          radius: 2

          property var day: gridData[index] || {
            level: 0,
            count: 0,
            date: ""
          }

          color: {
            switch (day.level) {
            case 0:
              return Colors.level0Contrib;
            case 1:
              return Colors.level1Contrib;
            case 2:
              return Colors.level2Contrib;
            case 3:
              return Colors.level3Contrib;
            case 4:
              return Colors.level4Contrib;
            default:
              return Colors.level0Contrib;
            }
          }

          MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true

            onContainsMouseChanged: {
              if (containsMouse && day.date !== "" && day.count !== 0 && Config.dashContribToolTip) {
                tooltipLoader.active = true;
                tooltipLoader.item.dayData = day;
                tooltipLoader.item.updatePosition(commitSquares);
              } else {
                tooltipLoader.active = false;
              }
            }
          }
        }
      }
    } // END OF CONTRIB GRAPH GRID

    // Header // bottom header =======================
    // RowLayout {
    //   Layout.fillWidth: true
    //
    //   Text {
    //     text: `@${username}'s Contributions`
    //     color: Colors.accentColor
    //     font.pixelSize: 11
    //     font.bold: true
    //     Layout.alignment: Qt.AlignBottom
    //     Layout.leftMargin: 19
    //   }
    //
    //   Item {  // Spacer
    //     Layout.fillWidth: true
    //   }
    //
    //   Text {
    //     text: contributionData.length > 0 ?
    //       `${contributionData.reduce((sum, d) => sum + d.count, 0)} total` : ""
    //     color: Colors.accent2Color
    //     font.pixelSize: 19
    //     font.bold: true
    //     Layout.rightMargin: 22
    //     Layout.alignment: Qt.AlignBottom
    //   }
    // }
    // // ==================================================

  }
}
