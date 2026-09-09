import QtQuick

// A draggable cluster of blocks (addition). It rests at (restX, restY) — set by
// the parent — and is held there by a Binding that releases only while dragging,
// so it never fights the layout and never gets stuck after a drop that missed.
Item {
  id: grp
  property string groupId: ""
  property int count: 1
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property bool poured: false
  property real restX: 0
  property real restY: 0
  readonly property bool dragging: dragArea.drag.active

  width: grid.implicitWidth + 18
  height: grid.implicitHeight + 18
  visible: !poured
  z: dragging ? 10 : 1

  Binding on x { when: !grp.dragging; value: grp.restX; restoreMode: Binding.RestoreBinding }
  Binding on y { when: !grp.dragging; value: grp.restY; restoreMode: Binding.RestoreBinding }
  Behavior on x { enabled: !grp.reduceMotion && !grp.dragging; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
  Behavior on y { enabled: !grp.reduceMotion && !grp.dragging; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

  Rectangle {
    anchors.fill: parent
    radius: 14
    color: grp.dragging ? Qt.rgba(grp.tint.r, grp.tint.g, grp.tint.b, 0.18) : Qt.rgba(1, 1, 1, 0.04)
    border.width: 2
    border.color: grp.dragging ? grp.tint : Qt.rgba(1, 1, 1, 0.10)
  }

  Grid {
    id: grid
    anchors.centerIn: parent
    columns: Math.min(4, Math.max(1, grp.count))
    spacing: 5
    Repeater {
      model: grp.count
      delegate: Block { tint: grp.tint; reduceMotion: grp.reduceMotion }
    }
  }

  Drag.active: dragArea.drag.active
  Drag.hotSpot.x: width / 2
  Drag.hotSpot.y: height / 2
  Drag.keys: [grp.groupId]

  MouseArea {
    id: dragArea
    anchors.fill: parent
    cursorShape: grp.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    drag.target: grp
    onReleased: {
      if (grp.Drag.target) grp.Drag.drop()
      // If the drop wasn't accepted, `poured` is still false and the x/y
      // Bindings snap the group home on their own.
    }
  }
}
