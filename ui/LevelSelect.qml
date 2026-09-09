import QtQuick
import "../logic/progression.js" as Progression

FocusScope {
  id: root
  property var game
  signal play(int level)
  signal close()

  Keys.onEscapePressed: root.close()

  readonly property string world: game ? game.world : "add"
  readonly property var meta: Progression.WORLD_META[world]
  readonly property int levelCount: meta ? meta.levels : 7

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 720)
    spacing: Math.round(28 * (game ? game.textScale : 1))

    // ---- header --------------------------------------------------------
    Item {
      width: parent.width
      height: title.implicitHeight

      Text {
        id: title
        anchors.left: parent.left
        text: (meta ? meta.name : "Math") + "  " + (meta ? meta.symbol : "+")
        color: game ? game.colText : "#edeffb"
        font.family: game ? game.fontFamily : "sans-serif"
        font.pixelSize: Math.round(40 * (game ? game.textScale : 1))
        font.bold: true
      }

      Rectangle {
        anchors.right: closeBtn.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: starText.implicitWidth + 34
        height: starText.implicitHeight + 14
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.06)
        Text {
          id: starText
          anchors.centerIn: parent
          text: "★ " + (game ? Progression.worldStars(game.progress, root.world) : 0)
                + " / " + Progression.maxStars(root.world)
          color: game ? game.colStar : "#ffce54"
          font.family: game ? game.fontFamily : "sans-serif"
          font.pixelSize: Math.round(17 * (game ? game.textScale : 1))
          font.bold: true
        }
      }

      Rectangle {
        id: closeBtn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40; radius: 20
        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
        Text {
          anchors.centerIn: parent
          text: "←"
          color: game ? game.colMuted : "#9aa2c8"
          font.pixelSize: 20
        }
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
      text: "Pick a level"
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(16 * (game ? game.textScale : 1))
    }

    // ---- level grid ---------------------------------------------------
    Grid {
      id: grid
      width: parent.width
      columns: Math.max(2, Math.floor(width / 150))
      spacing: 16

      Repeater {
        model: root.levelCount
        delegate: Item {
          id: cell
          required property int index
          readonly property int level: index + 1
          readonly property bool unlocked: game ? Progression.isUnlocked(game.progress, root.world, level) : level === 1
          readonly property int stars: game ? Progression.bestStars(game.progress, root.world, level) : 0
          readonly property var blurb: Progression.LEVEL_BLURBS[root.world]
          width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
          height: width * 0.82

          Rectangle {
            anchors.fill: parent
            radius: width * 0.14
            color: !cell.unlocked ? Qt.rgba(1, 1, 1, 0.03)
                 : cellMouse.containsMouse ? (game ? game.colSurfaceAlt : "#363b54")
                 : (game ? game.colSurface : "#2b2f42")
            border.width: 2
            border.color: cell.unlocked ? Qt.rgba(game ? game.worldColor[root.world] : "#5bc98c", cellMouse.containsMouse ? 0.9 : 0.35)
                                        : Qt.rgba(1, 1, 1, 0.05)
            opacity: cell.unlocked ? 1.0 : 0.55

            Column {
              anchors.centerIn: parent
              spacing: 6
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.unlocked ? cell.level : "🔒"
                color: game ? game.colText : "#edeffb"
                font.family: game ? game.fontFamily : "sans-serif"
                font.pixelSize: Math.round(cell.height * 0.34)
                font.bold: true
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: cell.blurb && cell.blurb[cell.index] !== undefined
                text: cell.blurb ? (cell.blurb[cell.index] || "") : ""
                color: game ? game.colMuted : "#9aa2c8"
                font.family: game ? game.fontFamily : "sans-serif"
                font.pixelSize: Math.round(12 * (game ? game.textScale : 1))
              }
              StarRow {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: cell.unlocked
                filled: cell.stars
                size: 16
                litColor: game ? game.colStar : "#ffce54"
              }
            }

            MouseArea {
              id: cellMouse
              anchors.fill: parent
              enabled: cell.unlocked
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.play(cell.level)
            }
          }
        }
      }
    }
  }
}
