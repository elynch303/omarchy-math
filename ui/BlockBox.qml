import QtQuick

// A box that can be open (contents visible) or shut. When shut, a "?" cover
// slides down over the contents so kids can't just count the blocks.
// Put the blocks (a Grid, a SubBlockField, ...) inside as children.
Item {
  id: box
  property color tint: "#5bc98c"
  property bool lidOpen: true
  property bool reduceMotion: false
  default property alias content: body.data

  implicitWidth: 320
  implicitHeight: 120

  Rectangle {
    id: bodyBg
    anchors.fill: parent
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 2
    border.color: Qt.rgba(box.tint.r, box.tint.g, box.tint.b, box.lidOpen ? 0.4 : 0.85)
    // rim across the top, so it still reads as a box
    Rectangle {
      width: parent.width
      height: 8
      radius: 4
      color: Qt.rgba(box.tint.r, box.tint.g, box.tint.b, 0.5)
    }
    clip: !box.lidOpen
    Item { id: body; anchors.fill: parent }
  }

  // the "?" cover — slides down over the contents when the box is shut
  Rectangle {
    id: cover
    width: parent.width
    height: parent.height + 2
    radius: 16
    color: box.tint
    y: box.lidOpen ? -height : -1
    visible: y > -height + 1
    Behavior on y {
      enabled: !box.reduceMotion
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Text {
      anchors.centerIn: parent
      text: "?"
      color: "#ffffff"
      font.pixelSize: 54
      font.bold: true
    }
  }
}
