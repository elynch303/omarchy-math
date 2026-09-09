import QtQuick

// A single draggable block (used for subtraction). When `gone` becomes true it
// pops out. Emits droppedOnTarget when released over `targetArea`.
Item {
  id: db
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property bool gone: false
  property var targetArea: null
  signal droppedOnTarget()

  width: 34
  height: 34
  opacity: gone ? 0 : 1
  scale: gone ? 0.3 : (dragArea.drag.active ? 1.1 : 1)
  enabled: !gone

  Behavior on opacity { NumberAnimation { duration: 220 } }
  Behavior on scale { enabled: !db.reduceMotion; NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
  Behavior on x { enabled: !db.reduceMotion && !dragArea.drag.active; NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
  Behavior on y { enabled: !db.reduceMotion && !dragArea.drag.active; NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

  Block {
    id: face
    anchors.fill: parent
    tint: db.tint
    reduceMotion: db.reduceMotion
  }

  property real homeX: x
  property real homeY: y

  Drag.active: dragArea.drag.active
  Drag.hotSpot.x: width / 2
  Drag.hotSpot.y: height / 2

  MouseArea {
    id: dragArea
    anchors.fill: parent
    cursorShape: Qt.OpenHandCursor
    drag.target: db
    onReleased: {
      var onTarget = db.Drag.target === db.targetArea && db.targetArea !== null
      db.x = db.homeX
      db.y = db.homeY
      if (onTarget) db.droppedOnTarget()
    }
  }
}
