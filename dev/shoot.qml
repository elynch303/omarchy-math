import QtQuick
import ".."

// Headless screenshot driver. Run offscreen:
//   QT_QPA_PLATFORM=offscreen qml dev/shoot.qml
// Writes /tmp/km-*.png for each screen without touching the live desktop.
Window {
  id: win
  visible: true
  width: 900
  height: 680
  color: "#1f2230"
  property int step: 0

  Game {
    id: game
    anchors.fill: parent
    reduceMotion: true
    progress: ({
      version: 1,
      settings: { sound: true, reduceMotion: true, largeText: false },
      worlds: { add: { levels: {
        "1": { bestStars: 3, bestScore: 10, plays: 3 },
        "2": { bestStars: 2, bestScore: 9, plays: 1 }
      } } }
    })
    onPersist: function (n) {}
  }

  function grab(name, done) {
    game.grabToImage(function (res) {
      res.saveToFile("/tmp/km-" + name + ".png")
      console.log("saved /tmp/km-" + name + ".png")
      if (done) done()
    })
  }

  Timer {
    interval: 400
    repeat: true
    running: true
    onTriggered: {
      win.step += 1
      switch (win.step) {
        case 1: grab("1-levels"); break
        case 2: game.startLevel(3); break
        case 3: grab("2-round"); break
        case 4:
          game.correctCount = 8
          game.bestStreak = 6
          game.finish()
          break
        case 5: grab("3-result"); break
        case 6: Qt.quit(); break
      }
    }
  }
}
