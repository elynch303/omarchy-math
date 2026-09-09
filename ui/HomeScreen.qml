import QtQuick
import "../logic/progression.js" as Progression

FocusScope {
  id: root
  property var game
  signal openWorld(string world)
  signal grownUps()
  signal close()

  focus: visible
  onVisibleChanged: if (visible) forceActiveFocus()
  Keys.onEscapePressed: root.close()

  readonly property var progress: game ? game.progress : null

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 720)
    spacing: Math.round(26 * (game ? game.textScale : 1))

    Item {
      width: parent.width
      height: heading.implicitHeight

      Text {
        id: heading
        anchors.left: parent.left
        text: "Kids Math"
        color: game ? game.colText : "#edeffb"
        font.family: game ? game.fontFamily : "sans-serif"
        font.pixelSize: Math.round(42 * (game ? game.textScale : 1))
        font.bold: true
      }

      Row {
        anchors.right: closeBtn.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
          text: "★"
          color: game ? game.colStar : "#ffce54"
          font.pixelSize: Math.round(22 * (game ? game.textScale : 1))
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: (game ? Progression.totalStars(game.progress) : 0) + " / " + Progression.maxStars()
          color: game ? game.colText : "#edeffb"
          font.family: game ? game.fontFamily : "sans-serif"
          font.pixelSize: Math.round(18 * (game ? game.textScale : 1))
          font.bold: true
        }
      }

      Rectangle {
        id: closeBtn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40; radius: 20
        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
        Text { anchors.centerIn: parent; text: "✕"; color: game ? game.colMuted : "#9aa2c8"; font.pixelSize: 18 }
        MouseArea {
          id: closeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.close()
        }
      }
    }

    Text {
      text: "Choose what to practise"
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(16 * (game ? game.textScale : 1))
    }

    Grid {
      id: grid
      width: parent.width
      columns: width < 460 ? 1 : 2
      spacing: 18

      Repeater {
        model: Progression.WORLD_ORDER
        delegate: Item {
          id: cell
          required property string modelData
          readonly property var meta: Progression.WORLD_META[modelData]
          readonly property color tint: game ? game.worldColor[modelData] : "#5bc98c"
          readonly property int stars: game ? Progression.worldStars(game.progress, modelData) : 0
          readonly property int maxStars: Progression.maxStars(modelData)
          width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
          height: Math.round(150 * (game ? game.textScale : 1))

          Rectangle {
            anchors.fill: parent
            radius: 22
            color: worldMouse.containsMouse ? (game ? game.colSurfaceAlt : "#363b54")
                                            : (game ? game.colSurface : "#2b2f42")
            border.width: 2
            border.color: Qt.rgba(cell.tint.r, cell.tint.g, cell.tint.b, worldMouse.containsMouse ? 0.95 : 0.4)

            Row {
              anchors.fill: parent
              anchors.margins: 18
              spacing: 16

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 62; height: 62; radius: 18
                color: Qt.rgba(cell.tint.r, cell.tint.g, cell.tint.b, 0.18)
                Text {
                  anchors.centerIn: parent
                  text: cell.meta.symbol
                  color: cell.tint
                  font.pixelSize: 38
                  font.bold: true
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 62 - 16
                spacing: 8

                Text {
                  text: cell.meta.name
                  color: game ? game.colText : "#edeffb"
                  font.family: game ? game.fontFamily : "sans-serif"
                  font.pixelSize: Math.round(23 * (game ? game.textScale : 1))
                  font.bold: true
                }

                Row {
                  spacing: 6
                  Text {
                    text: "★"
                    color: game ? game.colStar : "#ffce54"
                    font.pixelSize: 15
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: cell.stars + " / " + cell.maxStars
                    color: game ? game.colMuted : "#9aa2c8"
                    font.family: game ? game.fontFamily : "sans-serif"
                    font.pixelSize: 14
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 7
                  radius: 3.5
                  color: Qt.rgba(1, 1, 1, 0.08)
                  Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * (cell.maxStars > 0 ? cell.stars / cell.maxStars : 0)
                    color: cell.tint
                  }
                }
              }
            }

            MouseArea {
              id: worldMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openWorld(cell.modelData)
            }
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "For grown-ups"
      color: game ? game.colMuted : "#9aa2c8"
      opacity: guMouse.containsMouse ? 1 : 0.6
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(14 * (game ? game.textScale : 1))
      MouseArea {
        id: guMouse
        anchors.fill: parent
        anchors.margins: -10
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.grownUps()
      }
    }
  }
}
