import QtQuick
import QtQuick.Layouts
import qs.Theme

// Calendário simples do mês atual - mês/ano escrito em cima, grade de dias
// embaixo com o dia de hoje marcado. Só exibição, sem navegação entre meses
// (não foi pedido).
ColumnLayout {
    id: root

    readonly property var months: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]
    readonly property var weekdayLabels: ["D", "S", "T", "Q", "Q", "S", "S"]

    readonly property date today: new Date()
    readonly property int year: today.getFullYear()
    readonly property int month: today.getMonth()
    readonly property int todayDate: today.getDate()

    readonly property int firstWeekday: new Date(year, month, 1).getDay()
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    // Array plano de 42 posições (6 semanas) - 0 marca uma célula vazia
    // (antes do dia 1 ou depois do último dia do mês).
    readonly property var cells: {
        const list = []
        for (let i = 0; i < firstWeekday; i++) list.push(0)
        for (let d = 1; d <= daysInMonth; d++) list.push(d)
        while (list.length < 42) list.push(0)
        return list
    }

    spacing: 8

    Text {
        text: root.months[root.month] + " de " + root.year
        color: Colors.foreground
        font.pixelSize: Colors.fontSizeSmall
        font.family: Colors.fontFamily
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
    }

    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: root.weekdayLabels

            delegate: Text {
                required property string modelData

                Layout.preferredWidth: 24
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.foregroundMuted
                font.pixelSize: 10
                font.family: Colors.fontFamily
            }
        }

        Repeater {
            model: root.cells

            delegate: Rectangle {
                required property int modelData

                readonly property bool isToday: modelData === root.todayDate

                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: isToday ? Colors.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData === 0 ? "" : parent.modelData
                    color: parent.isToday ? Colors.background : Colors.foreground
                    font.pixelSize: 11
                    font.family: Colors.fontFamily
                    font.bold: parent.isToday
                }
            }
        }
    }
}
