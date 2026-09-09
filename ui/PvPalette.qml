import QtQuick

// The three tiers of blocks to build with: 10, 5, 1. Each is an endless source
// (a bin with a faint stack behind it) — tap a piece to add that value, or drag
// it onto `targetArea`. It springs back so the bin never empties.
Row {
  id: pal
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property var targetArea: null
  property bool active: true
  signal pick(int value)

  spacing: 18

  Repeater {
    model: [10, 5, 1]
    delegate: Item {
      id: bin
      required property int modelData
      width: Math.max(58, pv.width + 20)
      height: 118

      // "there's plenty" — faint copies behind
      PvBlock {
        value: bin.modelData; tint: pal.tint
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 5
        anchors.bottomMargin: -4
        opacity: 0.25
      }
      PvBlock {
        value: bin.modelData; tint: pal.tint
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 2
        anchors.bottomMargin: -2
        opacity: 0.4
      }

      Item {
        id: piece
        width: pv.width
        height: pv.height
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property bool dragging: ma.drag.active
        z: dragging ? 10 : 1

        Binding on x { when: !piece.dragging; value: 0; restoreMode: Binding.RestoreBinding }
        Binding on y { when: !piece.dragging; value: 0; restoreMode: Binding.RestoreBinding }
        Behavior on x { enabled: !pal.reduceMotion && !piece.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutBack } }
        Behavior on y { enabled: !pal.reduceMotion && !piece.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutBack } }

        PvBlock {
          id: pv
          value: bin.modelData
          tint: pal.tint
          reduceMotion: pal.reduceMotion
        }

        Drag.active: ma.drag.active
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        MouseArea {
          id: ma
          anchors.fill: parent
          enabled: pal.active
          cursorShape: piece.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          drag.target: piece
          onClicked: if (!piece.dragging) pal.pick(bin.modelData)
          onReleased: {
            if (piece.Drag.target === pal.targetArea && pal.targetArea) pal.pick(bin.modelData)
          }
        }
      }
    }
  }
}
