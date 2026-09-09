import QtQuick
import "../logic/progression.js" as Progression

FocusScope {
  id: root
  property var game
  signal playAgain()
  signal nextLevel()
  signal backToLevels()

  focus: visible
  onVisibleChanged: if (visible) { forceActiveFocus(); starPop.restart() }

  readonly property int stars: game ? game.lastStars : 0
  readonly property int correct: game ? game.correctCount : 0
  readonly property int total: game ? game.questions.length : 10
  readonly property bool hasNext: game
    && Progression.isUnlocked(game.progress, game.world, game.level + 1)

  property real starScale: 0.4
  NumberAnimation { id: starPop; target: root; property: "starScale"; from: 0.4; to: 1.0; duration: 420; easing.type: Easing.OutBack }

  Keys.onEscapePressed: root.backToLevels()
  Keys.onReturnPressed: root.hasNext ? root.nextLevel() : root.playAgain()

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 520)
    spacing: Math.round(22 * (game ? game.textScale : 1))

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: "Round done!"
      color: game ? game.colText : "#edeffb"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(30 * (game ? game.textScale : 1))
      font.bold: true
    }

    StarRow {
      anchors.horizontalCenter: parent.horizontalCenter
      filled: root.stars
      max: 3
      size: Math.round(58 * (game ? game.textScale : 1))
      scale: root.starScale
      litColor: game ? game.colStar : "#ffce54"
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.correct + " / " + root.total + " right"
      color: game ? game.colText : "#edeffb"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(24 * (game ? game.textScale : 1))
      font.bold: true
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      text: {
        if (root.stars === 3) return "Perfect! Every single one."
        if (root.stars === 2) return "So close to perfect — one more go?"
        if (root.stars === 1) return "Good work. A bit more practice and you've got this."
        return "Tricky round. Try it again — you'll do better."
      }
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(16 * (game ? game.textScale : 1))
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: game && game.bestStreak >= 4
      text: "Best streak: " + (game ? game.bestStreak : 0) + " in a row 🔥"
      color: game ? game.colStar : "#ffce54"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(15 * (game ? game.textScale : 1))
    }

    // ---- actions -----------------------------------------------------
    Column {
      width: parent.width
      spacing: 12

      ResultButton {
        width: parent.width
        visible: root.hasNext
        label: "Next level  →"
        primary: true
        game: root.game
        onClicked: root.nextLevel()
      }
      ResultButton {
        width: parent.width
        label: "Play again"
        primary: !root.hasNext
        game: root.game
        onClicked: root.playAgain()
      }
      ResultButton {
        width: parent.width
        label: "Back to levels"
        game: root.game
        onClicked: root.backToLevels()
      }
    }
  }
}
