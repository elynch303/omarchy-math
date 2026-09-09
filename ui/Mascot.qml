import QtQuick

// A friendly no-assets mascot. `mood`: idle | happy | oops | think
Item {
  id: m
  property string mood: "idle"
  property color bodyColor: "#5bc98c"
  property color faceColor: "#10131f"
  property bool reduceMotion: false
  implicitWidth: 76
  implicitHeight: 76

  Rectangle {
    id: body
    anchors.fill: parent
    radius: width * 0.5
    color: m.bodyColor
    scale: m.mood === "happy" ? 1.05 : 1.0
    Behavior on scale {
      enabled: !m.reduceMotion
      NumberAnimation { duration: 220; easing.type: Easing.OutBack }
    }
    Behavior on color { enabled: !m.reduceMotion; ColorAnimation { duration: 200 } }

    // eyes
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.32
      spacing: parent.width * 0.2
      Repeater {
        model: 2
        delegate: Rectangle {
          width: body.width * 0.11
          height: width
          radius: width * 0.5
          color: m.faceColor
        }
      }
    }

    // flat mouth for the calm mood
    Rectangle {
      visible: m.mood === "idle"
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.62
      width: parent.width * 0.26
      height: parent.width * 0.06
      radius: height * 0.5
      color: m.faceColor
    }

    // curved mouth (smile / frown) for happy + oops
    Canvas {
      id: curve
      anchors.fill: parent
      visible: m.mood === "happy" || m.mood === "oops"
      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = m.faceColor
        ctx.lineWidth = width * 0.085
        ctx.lineCap = "round"
        ctx.beginPath()
        var cx = width / 2
        var r = width * 0.24
        if (m.mood === "happy") ctx.arc(cx, height * 0.5, r, 0.15 * Math.PI, 0.85 * Math.PI)
        else ctx.arc(cx, height * 0.78, r, -0.82 * Math.PI, -0.18 * Math.PI)
        ctx.stroke()
      }
      Connections {
        target: m
        function onMoodChanged() { curve.requestPaint() }
        function onFaceColorChanged() { curve.requestPaint() }
      }
    }

    // "thinking" dots
    Row {
      visible: m.mood === "think"
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.44
      spacing: parent.width * 0.06
      Repeater {
        model: 3
        delegate: Rectangle {
          required property int index
          width: body.width * 0.07
          height: width
          radius: width * 0.5
          color: m.faceColor
          opacity: 0.4 + 0.2 * index
        }
      }
    }
  }
}
