import QtQuick

// One big tappable answer tile. `phase` drives its look:
//   idle | cursor | correct | wrong | dim
Rectangle {
  id: tile
  property string label: ""
  property int hotkey: 0            // 1..4, shown as a small corner hint
  property string phase: "idle"
  property color surface: "#2b2f42"
  property color surfaceAlt: "#363b54"
  property color textColor: "#edeffb"
  property color accent: "#7aa2f7"
  property color correctColor: "#63d0a0"
  property color wrongColor: "#f4a6c0"
  property string fontFamily: "sans-serif"
  property real textScale: 1.0
  property bool reduceMotion: false
  signal picked()

  radius: Math.min(width, height) * 0.16
  border.width: phase === "cursor" ? 3 : 2
  border.color: phase === "correct" ? correctColor
              : phase === "wrong" ? wrongColor
              : phase === "cursor" ? accent
              : Qt.rgba(1, 1, 1, 0.08)
  color: phase === "correct" ? Qt.rgba(correctColor.r, correctColor.g, correctColor.b, 0.22)
       : phase === "wrong" ? Qt.rgba(wrongColor.r, wrongColor.g, wrongColor.b, 0.22)
       : phase === "cursor" ? surfaceAlt
       : surface
  opacity: phase === "dim" ? 0.4 : 1.0

  scale: mouse.pressed && tile.enabled ? 0.97 : 1.0
  Behavior on scale { enabled: !tile.reduceMotion; NumberAnimation { duration: 90 } }
  Behavior on color { enabled: !tile.reduceMotion; ColorAnimation { duration: 140 } }
  Behavior on opacity { NumberAnimation { duration: 140 } }

  Text {
    anchors.centerIn: parent
    text: tile.label
    color: tile.textColor
    font.family: tile.fontFamily
    font.pixelSize: Math.round(Math.min(tile.width * 0.34, tile.height * 0.5) * tile.textScale)
    font.bold: true
  }

  Text {
    visible: tile.hotkey > 0 && tile.phase !== "correct" && tile.phase !== "wrong"
    anchors { left: parent.left; top: parent.top; margins: Math.round(tile.height * 0.12) }
    text: tile.hotkey
    color: tile.textColor
    opacity: 0.35
    font.family: tile.fontFamily
    font.pixelSize: Math.round(tile.height * 0.16)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: tile.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: tile.picked()
  }
}
