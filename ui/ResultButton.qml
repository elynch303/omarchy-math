import QtQuick

Rectangle {
  id: btn
  property string label: ""
  property bool primary: false
  property var game
  signal clicked()

  height: Math.round(52 * (game ? game.textScale : 1))
  radius: height * 0.28
  color: primary
    ? (mouse.containsMouse ? Qt.lighter(game ? game.colAccent : "#7aa2f7", 1.12) : (game ? game.colAccent : "#7aa2f7"))
    : (mouse.containsMouse ? (game ? game.colSurfaceAlt : "#363b54") : (game ? game.colSurface : "#2b2f42"))
  border.width: primary ? 0 : 2
  border.color: Qt.rgba(1, 1, 1, 0.08)
  scale: mouse.pressed ? 0.98 : 1.0
  Behavior on scale { enabled: !(game && game.reduceMotion); NumberAnimation { duration: 90 } }

  Text {
    anchors.centerIn: parent
    text: btn.label
    color: btn.primary ? "#10131f" : (game ? game.colText : "#edeffb")
    font.family: game ? game.fontFamily : "sans-serif"
    font.pixelSize: Math.round(18 * (game ? game.textScale : 1))
    font.bold: true
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: btn.clicked()
  }
}
