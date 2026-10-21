import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Widgets
import qs.State
import qs.Modules.Notifications
import qs.Modules.Sidebar.RumdaConfig

// RumdaNotifications: toasts de notificação no estilo Rumda (entram
// deslizando da direita, com
// barra de tempo, ações do app e preview do print de tela.
//
// ESTE ARQUIVO NÃO TEM NotificationServer - ele SÓ LÊ a lista do
// NotificationService do shell (Modules/Notifications/NotificationService.qml),
// que é quem registra o servidor org.freedesktop.Notifications e guarda o
// histórico. A versão original do Rumda criava o servidor dela aqui, e com os
// dois no shell o segundo perdia o registro ("Could not register notification
// server") e as notificações iam parar num servidor só - sem chance de
// escolher.
//
// Troca em shell.qml: substitui o NotificationPopups (que fica comentado lá,
// pronto pra voltar).
Scope {
  id: root

  PanelWindow {
    anchors {
      top: true
      right: true
    }
    // Mesma margem de borda dos outros painéis do shell (Styles.edgeMargin).
    margins {
      top: Styles.edgeMargin
      right: Styles.edgeMargin
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Config.notifWidth + Config.notifShadowOffsetX
    implicitHeight: Math.max(1, col.implicitHeight)
    // Lista viva do NotificationService (o mesmo que o histórico e os popups
    // antigos usavam).
    visible: NotificationService.notifications.length > 0
    color: "transparent"

    ColumnLayout {
      id: col
      width: parent.width
      spacing: Styles.spacing

      Repeater {
        model: NotificationService.notifications

        delegate: Item {
          id: slot
          required property var modelData
          required property int index

          readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
          readonly property bool isShot: modelData.appName === "screenshot"
          readonly property real timeoutMs: modelData.expireTimeout > 0
            ? modelData.expireTimeout * 1000
            : Config.notifTimeout
          readonly property real offscreen: Config.notifWidth + Config.notifShadowOffsetX

          property real progress: 1.0
          property real slideX: offscreen
          property bool closing: false
          property bool dismissOnEnd: false

          function close(dismiss) {
            if (closing) return
            closing = true
            dismissOnEnd = dismiss
            slideOut.start()
          }

          Layout.fillWidth: true
          implicitHeight: card.height + Config.notifShadowOffsetY

          NumberAnimation on slideX {
            from: slot.offscreen
            to: 0
            duration: Config.notifSlideDuration
            easing.type: Easing.OutCubic
            running: true
          }

          NumberAnimation on progress {
            from: 1.0
            to: 0.0
            duration: slot.timeoutMs
            running: !slot.critical
            paused: cardHover.hovered || slot.closing
            onFinished: slot.close(false)
          }

          NumberAnimation {
            id: slideOut
            target: slot
            property: "slideX"
            to: slot.offscreen
            duration: Config.notifSlideDuration
            easing.type: Easing.InCubic
            onFinished: {
              if (slot.dismissOnEnd) slot.modelData.dismiss()
              else slot.modelData.expire()
            }
          }

          // Sombra do shell (Widgets/Shadow.qml) no lugar do "retângulo
          // deslocado" que o Rumda fingia com Colors.shadowColor.
          Shadow {
            target: card
            shadowHorizontalOffset: Config.notifShadowOffsetX - 3
            shadowVerticalOffset: Config.notifShadowOffsetY - 3
          }

          Rectangle {
            id: card
            x: slot.slideX
            y: 0
            z: 1
            width: slot.width - Config.notifShadowOffsetX
            height: innerCol.implicitHeight + Config.notifPadding * 2
              + Config.notifBarTopMargin + Config.notifBarHeight
            color: Styles.background
            // Borda de "erro" nas notificações críticas, como no Rumda.
            border.color: slot.critical ? Styles.danger : Styles.border
            border.width: 1
            radius: Styles.radiusShell

            HoverHandler { id: cardHover }

            MouseArea {
              anchors.fill: parent
              z: -1
              onClicked: slot.close(true)
            }

            ColumnLayout {
              id: innerCol
              x: Config.notifPadding
              y: Config.notifPadding
              width: parent.width - Config.notifPadding * 2
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                spacing: Config.notifPadding

                Item {
                  id: iconItem
                  width: Config.notifIconSize
                  height: Config.notifIconSize
                  Layout.alignment: Qt.AlignTop
                  visible: !slot.isShot

                  readonly property string src: {
                    const n = slot.modelData
                    if (n.image && n.image.length > 0) return n.image
                    if (n.appIcon && n.appIcon.length > 0) {
                      if (n.appIcon.startsWith("/")) return "file://" + n.appIcon
                      if (n.appIcon.indexOf("://") >= 0) return n.appIcon
                      return Quickshell.iconPath(n.appIcon, true)
                    }
                    return ""
                  }

                  Image {
                    id: appImg
                    anchors.fill: parent
                    source: iconItem.src
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: status === Image.Ready
                  }

                  // Sem ícone (ou ícone que não carregou): quadrado com a
                  // inicial do app, como o NotificationCard.qml do shell.
                  Rectangle {
                    anchors.fill: parent
                    visible: appImg.status !== Image.Ready
                    color: Styles.surface
                    radius: Styles.radiusSmall

                    Text {
                      anchors.centerIn: parent
                      text: (slot.modelData.appName || slot.modelData.summary || "?")
                        .charAt(0).toUpperCase()
                      color: Styles.accent
                      font.family: Styles.fontFamily
                      font.pixelSize: Math.round(Config.notifIconSize * 0.5)
                      font.bold: true
                    }
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 4

                  Text {
                    Layout.fillWidth: true
                    text: slot.modelData.summary
                    // Era um literal "#4E2E1F" (marrom do Rumda) - invisível
                    // em qualquer tema escuro.
                    color: Styles.foreground
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeTitle
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: slot.modelData.body
                    color: Styles.foregroundMuted
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeLarge
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                  }
                }
              }

              // Preview do print de tela (o app "screenshot" manda a imagem no
              // appIcon).
              Image {
                id: preview
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Config.notifShotHeight : 0
                source: {
                  if (!slot.isShot) return ""
                  const icon = slot.modelData.appIcon
                  if (!icon || icon.length === 0) return ""
                  if (icon.startsWith("/")) return "file://" + icon
                  if (icon.startsWith("file://")) return icon
                  return ""
                }
                sourceSize.width: 1200
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                clip: true
                smooth: true
                visible: slot.isShot && status === Image.Ready
              }

              Repeater {
                model: slot.modelData.actions
                delegate: Rectangle {
                  required property NotificationAction modelData
                  Layout.preferredWidth: Config.notifIconSize
                  height: Config.notifButtonHeight
                  color: Styles.surface
                  radius: Styles.radiusButton

                  Text {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: modelData.text
                    color: Styles.foreground
                    font.family: Styles.fontFamily
                    font.pixelSize: Styles.fontSizeSmall
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.invoke()
                  }
                }
              }
            }

            // Barra de tempo (encolhe conforme a notificação expira).
            Rectangle {
              x: Config.notifPadding
              y: card.height - Config.notifPadding - Config.notifBarHeight
              width: (card.width - Config.notifPadding * 2) * slot.progress
              height: Config.notifBarHeight
              color: slot.critical ? Styles.danger : Styles.accent
            }
          }
        }
      }
    }
  }
}