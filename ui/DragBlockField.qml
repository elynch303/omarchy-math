import QtQuick

// A grid of `total` blocks the kid drags one at a time into `targetArea`
// (a box, a bin). Up to `takeCount` can be taken; the block actually dropped is
// the one that leaves, and the rest reflow. Each block is pinned by a Binding
// that releases only while it's being dragged, so nothing gets stuck.
Item {
  id: field
  property int total: 10
  property int takeCount: 3
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property var targetArea: null

  property var present: []
  property int taken: 0
  signal took()
  signal allTaken()

  readonly property int cols: Math.max(1, Math.min(total <= 12 ? 5 : 7, total))
  readonly property real cell: total <= 12 ? 44 : 38
  readonly property real blockSize: cell - 6

  function slotX(slot) { return (slot % cols) * cell }
  function slotY(slot) { return Math.floor(slot / cols) * cell }

  implicitWidth: Math.min(total, cols) * cell - (cell - blockSize)
  implicitHeight: Math.ceil(total / cols) * cell - (cell - blockSize)

  function rebuild() {
    var a = []
    for (var i = 0; i < total; i++) a.push(i)
    present = a
    taken = 0
  }
  function take(idx) {
    if (taken >= takeCount) return
    var a = present.slice()
    var p = a.indexOf(idx)
    if (p === -1) return
    a.splice(p, 1)
    present = a
    taken = total - a.length
    took()
    if (taken === takeCount) allTaken()
  }

  // keyboard / programmatic helpers
  function takeLast() {
    if (present.length > 0) take(present[present.length - 1])
  }
  function giveBack() {
    if (taken <= 0) return
    for (var i = 0; i < total; i++) {
      if (present.indexOf(i) === -1) {
        var a = present.slice()
        a.push(i)
        a.sort(function (x, y) { return x - y })
        present = a
        taken = total - a.length
        return
      }
    }
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
      Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.InCubic } }

      Binding on x { when: !db.dragging; value: field.slotX(Math.max(0, db.slot)); restoreMode: Binding.RestoreBinding }
      Binding on y { when: !db.dragging; value: field.slotY(Math.max(0, db.slot)); restoreMode: Binding.RestoreBinding }
      Behavior on x { enabled: !field.reduceMotion && !db.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !field.reduceMotion && !db.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

      Block { anchors.fill: parent; tint: field.tint; reduceMotion: field.reduceMotion }

      Drag.active: ma.drag.active
      Drag.hotSpot.x: width / 2
      Drag.hotSpot.y: height / 2

      MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !db.gone && field.taken < field.takeCount
        cursorShape: db.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: db
        onReleased: {
          if (db.Drag.target === field.targetArea && field.targetArea) field.take(db.index)
          // otherwise the Bindings put it back
        }
      }
    }
  }
}
