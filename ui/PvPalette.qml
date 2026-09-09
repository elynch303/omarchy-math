import QtQuick

// The three tiers of blocks to build with: 10, 5, 1. Each piece is an endless
// source — drag it onto `targetArea` (or just tap it) to add that value; it
// springs back so the pal always has one of each.
Row {
  id: pal
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property var targetArea: null
  property bool active: true
  signal pick(int value)

  spacing: 16
  layoutDirection: Qt.RightToLeft   // 10, 5, 1 left-to-right visually

  Repeater {
    model: [1, 5, 10]
    delegate: Item {
      id: slot
      required property int modelData
      width: piece.width
      height: 106
      // keep the row baseline-aligned at the bottom
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
        Behavior on x { enabled: !pal.reduceMotion && !piece.dragging; NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on y { enabled: !pal.reduceMotion && !piece.dragging; NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        PvBlock {
          id: pv
          value: slot.modelData
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
          onClicked: if (!piece.dragging) pal.pick(slot.modelData)
          onReleased: {
            if (piece.Drag.target === pal.targetArea && pal.targetArea) pal.pick(slot.modelData)
          }
        }
      }
    }
  }
}
