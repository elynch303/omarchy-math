import QtQuick

// One static counting block.
Rectangle {
  id: b
  property color tint: "#5bc98c"
  property bool lit: true
  property bool reduceMotion: false

  width: 34
  height: 34
  radius: 9
  color: lit ? Qt.rgba(tint.r, tint.g, tint.b, 0.9) : Qt.rgba(1, 1, 1, 0.08)
  border.width: 1
  border.color: lit ? Qt.lighter(tint, 1.3) : Qt.rgba(1, 1, 1, 0.12)
  scale: lit ? 1 : 0.9

  Behavior on color { enabled: !b.reduceMotion; ColorAnimation { duration: 160 } }
  Behavior on scale { enabled: !b.reduceMotion; NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

  // little shine
  Rectangle {
    visible: b.lit
    x: parent.width * 0.18
    y: parent.height * 0.16
    width: parent.width * 0.28
    height: width
    radius: width * 0.5
    color: Qt.rgba(1, 1, 1, 0.28)
  }
}
