import QtQuick

// A draggable cluster of blocks (addition). Rests at (restX, restY) set by the
// parent, held there by a Binding that releases while dragging. When `poured`
// turns true it tumbles toward (sinkX, sinkY) — into the box — and fades.
Item {
  id: grp
  property string groupId: ""
  property int count: 1
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property bool poured: false
  property real restX: 0
  property real restY: 0
  property real sinkX: 0
  property real sinkY: 0
  readonly property bool dragging: dragArea.drag.active

  width: grid.implicitWidth + 18
  height: grid.implicitHeight + 18
  opacity: 1
  visible: opacity > 0.01
  z: dragging ? 10 : 1

  Binding on x { when: !grp.dragging && !grp.poured; value: grp.restX; restoreMode: Binding.RestoreBinding }
  Binding on y { when: !grp.dragging && !grp.poured; value: grp.restY; restoreMode: Binding.RestoreBinding }
  Behavior on x { enabled: !grp.reduceMotion && !grp.dragging && !grp.poured; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
  Behavior on y { enabled: !grp.reduceMotion && !grp.dragging && !grp.poured; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

  onPouredChanged: if (poured) sinkAnim.start()
  ParallelAnimation {
    id: sinkAnim
    NumberAnimation { target: grp; property: "x"; to: grp.sinkX; duration: grp.reduceMotion ? 0 : 360; easing.type: Easing.InCubic }
    NumberAnimation { target: grp; property: "y"; to: grp.sinkY; duration: grp.reduceMotion ? 0 : 360; easing.type: Easing.InCubic }
    NumberAnimation { target: grp; property: "scale"; to: 0.2; duration: grp.reduceMotion ? 0 : 360 }
    NumberAnimation { target: grp; property: "opacity"; to: 0; duration: grp.reduceMotion ? 0 : 360 }
  }

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
    columns: Math.min(5, Math.max(1, grp.count))
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
    enabled: !grp.poured
    cursorShape: grp.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    drag.target: grp
    onReleased: {
      if (grp.Drag.target) grp.Drag.drop()
    }
  }
}
