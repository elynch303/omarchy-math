import QtQuick

Rectangle {
  id: row
  property var game
  property string label: ""
  property bool checked: false
  property bool locked: false
  property string lockedNote: ""
  signal toggled(bool value)

  readonly property bool effective: checked || locked

  height: 48
  radius: 12
  color: mouse.containsMouse && !locked ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.04)
  opacity: locked ? 0.7 : 1

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    text: row.label + (row.locked && row.lockedNote ? "  —  " + row.lockedNote : "")
    color: game ? game.colText : "#edeffb"
    font.family: game ? game.fontFamily : "sans-serif"
    font.pixelSize: 15
  }

  Rectangle {
    id: track
    anchors.right: parent.right
    anchors.rightMargin: 14
    anchors.verticalCenter: parent.verticalCenter
    width: 46; height: 26; radius: 13
    color: row.effective ? (game ? game.colAccent : "#7aa2f7") : Qt.rgba(1, 1, 1, 0.14)
    Behavior on color { enabled: !(game && game.reduceMotion); ColorAnimation { duration: 140 } }

    Rectangle {
      width: 20; height: 20; radius: 10
      color: "#fff"
      y: 3
      x: row.effective ? track.width - width - 3 : 3
      Behavior on x { enabled: !(game && game.reduceMotion); NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: !row.locked
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: row.toggled(!row.checked)
  }
}
