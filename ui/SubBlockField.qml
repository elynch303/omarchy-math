import QtQuick

// A field of `total` blocks; the kid drags `toRemove` of them into `binArea`.
// The exact block dropped is the one that leaves; the rest reflow. Blocks are
// held in place by a Binding that releases only while a block is being dragged.
Item {
  id: field
  property int total: 8
  property int toRemove: 3
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property var binArea: null

  property var present: []
  property int removed: 0
  signal allRemoved()

  readonly property int cols: Math.max(1, Math.min(total <= 14 ? 5 : 7, total))
  readonly property real cell: total <= 14 ? 44 : 38
  readonly property real blockSize: cell - 6

  function slotX(slot) { return (slot % cols) * cell }
  function slotY(slot) { return Math.floor(slot / cols) * cell }

  implicitWidth: Math.min(total, cols) * cell - (cell - blockSize)
  implicitHeight: Math.ceil(total / cols) * cell - (cell - blockSize)

  function rebuild() {
    var a = []
    for (var i = 0; i < total; i++) a.push(i)
    present = a
    removed = 0
  }
  function remove(idx) {
    if (removed >= toRemove) return
    var a = present.slice()
    var p = a.indexOf(idx)
    if (p === -1) return
    a.splice(p, 1)
    present = a
    removed = total - a.length
    if (removed === toRemove) allRemoved()
  }

  Component.onCompleted: rebuild()
  onTotalChanged: rebuild()

  Repeater {
    model: field.total
    delegate: Item {
      id: db
      required property int index
      readonly property int slot: field.present.indexOf(index)
      readonly property bool gone: slot === -1
      readonly property bool dragging: ma.drag.active

      width: field.blockSize
      height: field.blockSize
      visible: !gone
      z: dragging ? 10 : 1
      scale: gone ? 0.2 : 1
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.InCubic } }

      Binding on x { when: !db.dragging; value: field.slotX(Math.max(0, db.slot)); restoreMode: Binding.RestoreBinding }
      Binding on y { when: !db.dragging; value: field.slotY(Math.max(0, db.slot)); restoreMode: Binding.RestoreBinding }
      Behavior on x { enabled: !field.reduceMotion && !db.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !field.reduceMotion && !db.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

      Block { anchors.fill: parent; tint: field.tint; reduceMotion: field.reduceMotion }

      Drag.active: ma.drag.active
      Drag.hotSpot.x: width / 2
      Drag.hotSpot.y: height / 2

      MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !db.gone
        cursorShape: db.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: db
        onReleased: {
          if (db.Drag.target === field.binArea && field.binArea) field.remove(db.index)
          // otherwise the Bindings put it back
        }
      }
    }
  }
}
