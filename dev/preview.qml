import QtQuick
import ".."

// Renders the marketplace preview image. Run offscreen:
//   QT_QPA_PLATFORM=offscreen /usr/bin/qml6 dev/preview.qml
Window {
  id: win
  visible: true
  width: 1280
  height: 800
  color: "#1b1e2b"

  Rectangle { anchors.fill: parent; color: "#1b1e2b" }

  Game {
    id: game
    anchors.fill: parent
    anchors.margins: 28
    reduceMotionPref: true
    progress: ({
      version: 1,
      settings: { sound: true },
      worlds: {
        add: { levels: { "1": { bestStars: 3, bestScore: 10, plays: 6 },
                         "2": { bestStars: 3, bestScore: 10, plays: 3 },
                         "3": { bestStars: 2, bestScore: 9, plays: 2 } } },
        sub: { levels: { "1": { bestStars: 3, bestScore: 10, plays: 2 },
                         "2": { bestStars: 1, bestScore: 7, plays: 1 } } },
        mul: { levels: { "1": { bestStars: 2, bestScore: 8, plays: 4 } } }
      }
    })
    onPersist: function (n) {}
  }

  Timer {
    interval: 500
    running: true
    onTriggered: {
      win.contentItem.grabToImage(function (res) {
        res.saveToFile(Qt.resolvedUrl("../preview.png").toString().replace("file://", ""))
        console.log("wrote preview.png")
        Qt.quit()
      })
    }
  }
}
