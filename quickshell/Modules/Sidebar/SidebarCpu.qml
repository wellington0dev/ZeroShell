import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Modules.Dashboard

// Indicador de CPU/RAM da sidebar (Fase 4).
//
// REAPROVEITA o singleton SystemStats (Modules/Dashboard/SystemStats.qml), que
// já roda UM `system-stats.sh` a cada 3s e publica cpuPercent/ramPercent/
// storagePercent/cpuTemp/netRxKBps/netTxKBps. Esta é a MESMA instância que a
// aba "Sistema" do Dashboard consome - nenhuma sondagem nova.
//
// A alternativa seria portar o CpuRamIndicator do Rumda, que roda DOIS
// processos próprios a cada update ("top -bn1 | grep '%Cpu(s)'" e "free |
// grep Mem"), duplicando leitura de CPU/RAM que o shell já faz de um jeito
// melhor (um processo só, com histórico). Por isso a referência do Rumda aqui
// é só o CONCEITO (dois indicadores empilhados), não a implementação.
//
// Efeito colateral aceito e consciente: como o SystemStats é singleton, ele
// passa a ser instanciado já no início do shell (antes só quando a aba Sistema
// do Dashboard era aberta pela 1ª vez). O custo é um `bash system-stats.sh` a
// cada 3s - o mesmo que já rodava sempre depois do primeiro uso do Dashboard.
//
// Este componente é o CONTEÚDO do SidebarItem (o container visual é adicionado
// pelo Sidebar.qml via SidebarItem). Aqui só definimos o conteúdo interno.
//
// A raiz é o próprio ColumnLayout (e não um Item com "anchors.fill"): o
// SidebarItem dimensiona o conteúdo pelo implicitWidth/implicitHeight dele, e
// um Item de raiz sempre reporta implicit 0 - o item inteiro da sidebar
// colapsaria num quadradinho vazio.
ColumnLayout {
    id: root

    spacing: Styles.spacing / 2

    // "12%" / "34%". As letras são o que distingue CPU de RAM numa coluna de
    // 40px de largura útil (56 - 2*Styles.spacing); sem elas os dois números
    // seriam indistinguíveis. A cor segue o mesmo critério do HeroMeter do
    // SystemTab: o número fica no accent normal e ganha o tom de danger acima
    // de 85%, que é o limiar em que "CPU em 90%" significa problema e não
    // só "estava compilando algo".
    Text {
        Layout.alignment: Qt.AlignHCenter

        text: SystemStats.cpuPercent + "%"
        color: SystemStats.cpuPercent >= 85 ? Styles.danger : Styles.foreground
        font.pixelSize: Styles.fontSizeSmallest
        font.family: Styles.fontFamily
    }

    Text {
        Layout.alignment: Qt.AlignHCenter

        text: SystemStats.ramPercent + "%"
        color: SystemStats.ramPercent >= 85 ? Styles.danger : Styles.foregroundMuted
        font.pixelSize: Styles.fontSizeSmallest
        font.family: Styles.fontFamily
    }
}