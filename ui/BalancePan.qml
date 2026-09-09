import QtQuick

// One pan of the balance scale, hanging BELOW the beam on strings so nothing
// overlaps the bar. `counterRotation` keeps it upright as the beam tilts.
//   - set `cardLabel` to show a number card (the "known" side)
//   - or set `pieces` (a list of block values) for the build side
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

  width: 210
  height: 130
  rotation: counterRotation
  transformOrigin: Item.Top

  readonly property real dishY: 52

  // hanger strings
  Rectangle { x: pan.width * 0.24; y: 2; width: 2; height: pan.dishY - 2; color: Qt.rgba(1, 1, 1, 0.22) }
  Rectangle { x: pan.width * 0.76 - 2; y: 2; width: 2; height: pan.dishY - 2; color: Qt.rgba(1, 1, 1, 0.22) }

  Rectangle {
    id: dish
    y: pan.dishY
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
    anchors.bottomMargin: 5
    anchors.horizontalCenter: parent.horizontalCenter
    width: cardText.implicitWidth + 26
    height: cardText.implicitHeight + 14
    radius: 11
    color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 2
    border.color: Qt.rgba(pan.tint.r, pan.tint.g, pan.tint.b, 0.6)
    Text {
      id: cardText
      anchors.centerIn: parent
      text: pan.cardLabel
      color: "#edeffb"
      font.family: pan.fontFamily
      font.pixelSize: 24
      font.bold: true
    }
  }

  // place-value blocks, wrapping so any number fit
  Flow {
    visible: !pan.isCard
    anchors.bottom: dish.top
    anchors.bottomMargin: 3
    anchors.horizontalCenter: parent.horizontalCenter
    width: pan.width - 6
    spacing: 3
    Repeater {
      model: pan.pieces
      delegate: PvBlock {
        required property var modelData
        required property int index
        value: modelData
        tint: pan.tint
        reduceMotion: pan.reduceMotion
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
