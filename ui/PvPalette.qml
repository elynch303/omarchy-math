import QtQuick

// The three tiers to build with: 10, 5, 1. Each is an endless source — tap a
// piece to add that value, or drag it onto `targetArea`. The piece is
// x/y-positioned (not anchored) so drag.target can actually move it, and a
// Binding springs it home on release.
Row {
  id: pal
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property var targetArea: null
  property bool active: true
  signal pick(int value)

  spacing: 22

  Repeater {
    model: [10, 5, 1]
    delegate: Item {
      id: bin
      required property int modelData
      width: 92
      height: 74

      // tap anywhere in the bin to add one (the piece itself is also draggable)
      MouseArea {
        anchors.fill: parent
        enabled: pal.active
        cursorShape: Qt.PointingHandCursor
        onClicked: pal.pick(bin.modelData)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: bin.modelData
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 12
        font.bold: true
      }

      // faint copy behind = "there's plenty"
      PvBlock {
        value: bin.modelData; tint: pal.tint
        x: bin.width / 2 - width / 2 + 4
        y: bin.height - height + 4
        opacity: 0.3
      }

      Item {
        id: piece
        width: pv.width
        height: pv.height
        readonly property real homeX: bin.width / 2 - width / 2
        readonly property real homeY: bin.height - height
        readonly property bool dragging: ma.drag.active
        z: dragging ? 20 : 1

        Binding on x { when: !piece.dragging; value: piece.homeX; restoreMode: Binding.RestoreBinding }
        Binding on y { when: !piece.dragging; value: piece.homeY; restoreMode: Binding.RestoreBinding }
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
