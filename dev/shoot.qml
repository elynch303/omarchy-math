import QtQuick
import ".."

// Headless screenshot driver. Run offscreen:
//   QT_QPA_PLATFORM=offscreen /usr/bin/qml6 dev/shoot.qml
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
    reduceMotionPref: true
    devSkipGate: true
    progress: ({
      version: 1,
      settings: { sound: true, reduceMotion: true, largeText: false },
      worlds: {
        add: { levels: { "1": { bestStars: 3, bestScore: 10, plays: 4 },
                         "2": { bestStars: 3, bestScore: 10, plays: 2 },
                         "3": { bestStars: 2, bestScore: 9, plays: 1 } } },
        mul: { levels: { "1": { bestStars: 3, bestScore: 10, plays: 2 },
                         "2": { bestStars: 1, bestScore: 7, plays: 3 } } },
        sub: { levels: { "1": { bestStars: 2, bestScore: 8, plays: 1 } } }
      }
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
    interval: 350
    repeat: true
    running: true
    onTriggered: {
      win.step += 1
      switch (win.step) {
        case 1: grab("1-home"); break
        // visit every world's level map so the per-world tint paths all run
        case 2: game.openWorld("add"); break
        case 3: game.openWorld("sub"); break
        case 4: game.openWorld("mul"); break
        case 5: grab("2-levels"); break
        case 6: game.startLevel(5); break
        case 7: grab("3-round"); break
        case 8:
          game.correctCount = 10
          game.bestStreak = 10
          game.finish()
          break
        case 9: grab("4-result"); break
        case 10: game.screen = "home"; break
        case 11: game.openWorld("div"); game.startLevel(6); break
        case 12: grab("5-round-div"); break
        case 13: game.screen = "grownups"; break
        case 14: grab("6-grownups"); break
        // block round (addition, intro level)
        case 15: game.screen = "home"; break
        case 16: game.openWorld("add"); game.startLevel(2); break
        case 17: grab("7-blocks-add-play"); break
        case 18: {
          var br = game.devBlockRound
          for (var i = 0; i < 40 && br.phase === "play"; i++) br.keyStep()
          break
        }
        case 22: grab("8-blocks-closed"); break
        case 24: game.devBlockRound.startReveal(game.devBlockRound.total); break
        case 30: grab("9-blocks-reveal"); break
        case 31: game.screen = "home"; break
        case 32: game.openWorld("sub"); game.startLevel(2); break
        case 33: grab("10-blocks-sub-play"); break
        case 34: Qt.quit(); break
      }
    }
  }
}
