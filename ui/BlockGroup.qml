import QtQuick

// A draggable cluster of blocks (used for addition). Drops onto a DropArea;
// if not dropped on a target it springs back to home.
Item {
  id: grp
  property string groupId: ""
  property int count: 1
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property real homeX: 0
  property real homeY: 0
  property bool poured: false

  width: grid.width + 16
  height: grid.height + 16
  visible: !poured
  opacity: dragArea.drag.active ? 0.9 : 1

  Behavior on x { enabled: !grp.reduceMotion && !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
  Behavior on y { enabled: !grp.reduceMotion && !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

  Rectangle {
    anchors.fill: parent
    radius: 14
    color: dragArea.drag.active ? Qt.rgba(grp.tint.r, grp.tint.g, grp.tint.b, 0.16) : "transparent"
    border.width: dragArea.drag.active ? 2 : 0
    border.color: grp.tint
  }

  Grid {
    id: grid
    anchors.centerIn: parent
    columns: Math.min(4, grp.count)
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
    cursorShape: Qt.OpenHandCursor
    drag.target: grp
    onReleased: {
      if (grp.Drag.target) {
        grp.Drag.drop()
      } else {
        grp.x = grp.homeX
        grp.y = grp.homeY
      }
    }
  }
}
