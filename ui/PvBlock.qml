import QtQuick

// A place-value block, laid out horizontally so it sits flat in a scale pan:
//   1  = a single cube
//   5  = a bar, five cubes wide
//   10 = a block, five wide by two tall
Rectangle {
  id: blk
  property int value: 1
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property real unit: 16

  readonly property int wUnits: value === 1 ? 1 : 5
  readonly property int hUnits: value === 10 ? 2 : 1

  width: wUnits * unit
  height: hUnits * unit
  radius: 5
  color: Qt.rgba(tint.r, tint.g, tint.b, 0.92)
  border.width: 1
  border.color: Qt.lighter(tint, 1.3)

  // segment grid
  Item {
    anchors.fill: parent
    visible: blk.value !== 1
    Repeater {
      model: blk.wUnits - 1
      delegate: Rectangle {
        required property int index
        height: parent.height; width: 1
        x: (index + 1) * blk.unit
        color: Qt.rgba(0, 0, 0, 0.2)
      }
    }
    Repeater {
      model: blk.hUnits - 1
      delegate: Rectangle {
        required property int index
        width: parent.width; height: 1
        y: (index + 1) * blk.unit
        color: Qt.rgba(0, 0, 0, 0.2)
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: blk.value
    visible: blk.value !== 1
    color: "#ffffff"
    font.bold: true
    font.pixelSize: 13
    style: Text.Outline
    styleColor: Qt.rgba(0, 0, 0, 0.35)
  }
}
