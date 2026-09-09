import QtQuick

// One pan of the balance scale. Hangs from a beam end; `counterRotation` keeps
// it upright while the beam tilts. Shows `count` blocks; the first `fixedCount`
// can't be removed, the rest are tap-to-take-off.
Item {
  id: pan
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property int count: 0
  property int fixedCount: 0
  property int split: -1
  property real counterRotation: 0
  property bool removable: true
  property bool dropActive: true
  property bool highlight: false
  signal removeTapped()

  readonly property alias dropArea: drop

  width: 150
  height: 150
  rotation: counterRotation
  transformOrigin: Item.Top

  // hanger
  Rectangle { x: pan.width * 0.2; width: 2; height: 24; color: Qt.rgba(1, 1, 1, 0.22) }
  Rectangle { x: pan.width * 0.8 - 2; width: 2; height: 24; color: Qt.rgba(1, 1, 1, 0.22) }

  Rectangle {
    id: dish
    y: 24
    width: parent.width
    height: 12
    radius: 6
    color: Qt.rgba(pan.tint.r, pan.tint.g, pan.tint.b,
                   (drop.containsDrag && pan.dropActive) || pan.highlight ? 0.95 : 0.5)
    border.width: 2
    border.color: (drop.containsDrag && pan.dropActive) || pan.highlight ? pan.tint : "transparent"
    Behavior on color { enabled: !pan.reduceMotion; ColorAnimation { duration: 150 } }
  }

  DropArea {
    id: drop
    anchors.fill: parent
    enabled: pan.dropActive
  }

  Grid {
    anchors.bottom: dish.top
    anchors.bottomMargin: 3
    anchors.horizontalCenter: parent.horizontalCenter
    columns: 5
    verticalItemAlignment: Grid.AlignBottom
    flow: Grid.LeftToRight
    spacing: 3
    Repeater {
      model: pan.count
      delegate: Item {
        required property int index
        readonly property bool isFixed: index < pan.fixedCount
        readonly property bool gapBefore: pan.split > 0 && index === pan.split && (index % 5) !== 0
        width: 20 + (gapBefore ? 8 : 0)
        height: 20
        Block {
          width: 20; height: 20
          anchors.right: parent.right
          tint: pan.tint
          reduceMotion: pan.reduceMotion
          opacity: parent.isFixed ? 0.7 : 1
        }
        MouseArea {
          anchors.fill: parent
          enabled: pan.removable && !parent.isFixed
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: pan.removeTapped()
        }
      }
    }
  }
}
