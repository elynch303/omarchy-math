import QtQuick

// A place-value block: 1 (unit cube), 5 (short rod), or 10 (long rod).
// Segment lines make the value readable at a glance.
Rectangle {
  id: blk
  property int value: 1
  property color tint: "#5bc98c"
  property bool reduceMotion: false

  property real unit: 18
  readonly property int cols: value === 10 ? 2 : 1
  readonly property int rows: value === 1 ? 1 : 5

  width: cols * unit
  height: rows * unit
  radius: 6
  color: Qt.rgba(tint.r, tint.g, tint.b, 0.92)
  border.width: 1
  border.color: Qt.lighter(tint, 1.3)

  // segment grid for 5s and 10s
  Item {
    anchors.fill: parent
    visible: blk.value !== 1
    Repeater {
      model: blk.rows - 1
      delegate: Rectangle {
        required property int index
        width: parent.width; height: 1
        y: (index + 1) * blk.unit
        color: Qt.rgba(0, 0, 0, 0.22)
      }
    }
    Repeater {
      model: blk.cols - 1
      delegate: Rectangle {
        required property int index
        height: parent.height; width: 1
        x: (index + 1) * blk.unit
        color: Qt.rgba(0, 0, 0, 0.22)
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: blk.value
    visible: blk.value !== 1
    color: "#ffffff"
    font.bold: true
    font.pixelSize: blk.value === 10 ? 16 : 13
    style: Text.Outline
    styleColor: Qt.rgba(0, 0, 0, 0.35)
  }
}
