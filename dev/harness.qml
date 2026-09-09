import QtQuick
import ".."

// Standalone runner for Game.qml — no Quickshell, no Omarchy shell, no bar.
// Lets us render and screenshot the game without touching the live desktop:
//
//   qml dev/harness.qml
//   QT_QPA_PLATFORM=offscreen qml dev/harness.qml   # for grabbing frames
//
// It stubs the persistence bridge with an in-memory progress doc so unlock /
// star logic is exercisable.
Window {
  id: win
  visible: true
  width: 900
  height: 680
  color: "#1f2230"
  title: "Kids Math — harness"

  Game {
    id: game
    anchors.fill: parent
    focus: true

    // Optional: preload some progress so later levels are reachable in a shot.
    // progress: ({ version: 1, settings: { sound: true },
    //   worlds: { add: { levels: { "1": { bestStars: 3, bestScore: 10, plays: 2 },
    //                               "2": { bestStars: 2, bestScore: 9, plays: 1 } } } } })

    onPersist: function (next) { console.log("[harness] persist:", JSON.stringify(next.worlds)) }
    onRequestClose: Qt.quit()
  }
}
