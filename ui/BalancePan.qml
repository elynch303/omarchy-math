import QtQuick

// One pan of the balance scale. Hangs from a beam end; `counterRotation` keeps
// it upright while the beam tilts.
//   - set `cardLabel` to show a number card (the "known" side)
//   - or set `pieces` (a list of block values) to show place-value blocks the
//     kid can tap to take back off
Item {
  id: pan
  property color tint: "#5bc98c"
  property bool reduceMotion: false
  property real counterRotation: 0
  property bool removable: true
  property bool dropActive: true
  property bool highlight: false
  property string cardLabel: ""
  property var pieces: []
  property string fontFamily: "sans-serif"
  signal pieceTapped(int index)

  readonly property alias dropArea: drop
  readonly property bool isCard: cardLabel.length > 0

  width: 168
  height: 150
  rotation: counterRotation
  transformOrigin: Item.Top

  // hanger
  Rectangle { x: pan.width * 0.22; width: 2; height: 24; color: Qt.rgba(1, 1, 1, 0.22) }
  Rectangle { x: pan.width * 0.78 - 2; width: 2; height: 24; color: Qt.rgba(1, 1, 1, 0.22) }

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
    enabled: pan.dropActive && !pan.isCard
  }

  // number card
  Rectangle {
    visible: pan.isCard
    anchors.bottom: dish.top
    anchors.bottomMargin: 6
    anchors.horizontalCenter: parent.horizontalCenter
    width: cardText.implicitWidth + 28
    height: cardText.implicitHeight + 16
    radius: 12
    color: Qt.rgba(1, 1, 1, 0.07)
    border.width: 2
    border.color: Qt.rgba(pan.tint.r, pan.tint.g, pan.tint.b, 0.6)
    Text {
      id: cardText
      anchors.centerIn: parent
      text: pan.cardLabel
      color: "#edeffb"
      font.family: pan.fontFamily
      font.pixelSize: 26
      font.bold: true
    }
  }

  // place-value blocks, tallest first, bottom-aligned on the dish
  Row {
    visible: !pan.isCard
    anchors.bottom: dish.top
    anchors.bottomMargin: 3
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 3
    Repeater {
      model: pan.pieces
      delegate: PvBlock {
        required property var modelData
        required property int index
        value: modelData
        tint: pan.tint
        reduceMotion: pan.reduceMotion
        anchors.bottom: parent.bottom
        MouseArea {
          anchors.fill: parent
          enabled: pan.removable
          cursorShape: Qt.PointingHandCursor
          onClicked: pan.pieceTapped(index)
        }
      }
    }
  }
}
