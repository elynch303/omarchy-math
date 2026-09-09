import QtQuick

// Row of up to `max` stars, `filled` of them lit.
Row {
  id: row
  property int filled: 0
  property int max: 3
  property real size: 22
  property color litColor: "#ffce54"
  property color dimColor: "#4a4f6a"
  property bool animate: false
  spacing: size * 0.22

  Repeater {
    model: row.max
    delegate: Text {
      required property int index
      text: "★"
      font.pixelSize: row.size
      color: index < row.filled ? row.litColor : row.dimColor
      scale: row.animate && index < row.filled ? 1.0 : (row.animate ? 0.6 : 1.0)
      opacity: index < row.filled ? 1.0 : 0.55
      Behavior on scale {
        enabled: row.animate
        NumberAnimation { duration: 260; easing.type: Easing.OutBack }
      }
    }
  }
}
