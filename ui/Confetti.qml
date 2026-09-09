import QtQuick

// Cheap, dependency-free confetti. Call burst() to fire once.
// Honours reduceMotion by doing nothing.
Item {
  id: fx
  property bool reduceMotion: false
  property var colors: ["#63d0a0", "#7aa2f7", "#ffce54", "#f4a6c0", "#c98adf"]
  property int pieces: 16

  // Each burst() bumps this; every piece watches it and re-runs its flight.
  property int salvo: 0

  function burst() {
    if (!fx.reduceMotion) fx.salvo += 1
  }

  Repeater {
    id: rep
    model: fx.pieces

    delegate: Item {
      id: piece
      required property int index
      anchors.centerIn: parent
      width: 1
      height: 1

      readonly property real dir: (index % 2) === 0 ? -1 : 1
      readonly property real spread: 40 + (index * 37) % 160
      readonly property real rise: 40 + (index * 53) % 70

      // Restart the flight whenever a new salvo is fired.
      Connections {
        target: fx
        function onSalvoChanged() {
          flight.stop()
          bit.x = 0
          bit.y = 0
          bit.opacity = 1
          bit.rotation = piece.index * 24
          flight.start()
        }
      }

      Rectangle {
        id: bit
        width: 6 + (piece.index % 3) * 2
        height: (piece.index % 2) === 0 ? width : width * 0.55
        radius: 1.5
        color: fx.colors[piece.index % fx.colors.length]
        opacity: 0
        transformOrigin: Item.Center
      }

      ParallelAnimation {
        id: flight
        NumberAnimation { target: bit; property: "x"; from: 0; to: piece.dir * piece.spread; duration: 750; easing.type: Easing.OutCubic }
        NumberAnimation { target: bit; property: "rotation"; from: piece.index * 24; to: piece.index * 24 + 260; duration: 750 }
        SequentialAnimation {
          NumberAnimation { target: bit; property: "y"; from: 0; to: -piece.rise; duration: 260; easing.type: Easing.OutCubic }
          NumberAnimation { target: bit; property: "y"; to: piece.rise + 70; duration: 490; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
          PauseAnimation { duration: 430 }
          NumberAnimation { target: bit; property: "opacity"; to: 0; duration: 320 }
        }
      }
    }
  }
}
