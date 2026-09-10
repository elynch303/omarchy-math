import QtQuick

// Balance-scale round for the intro levels (add/sub, levels 1-2).
//
// The left pan is a number card ("5 + 2" / "8 - 3"). The kid builds the answer
// on the right pan out of 1-, 5- and 10-blocks until the beam is level.
// No answer to pick — balancing IS the answer.
FocusScope {
  id: root
  property var game
  signal quit()

  focus: visible
  onVisibleChanged: if (visible) forceActiveFocus()

  readonly property var q: (game && game.questions.length > game.qIndex) ? game.questions[game.qIndex] : null
  readonly property int answer: q ? q.answer : 0
  readonly property color tint: {
    var c = (game && game.worldColor && q) ? game.worldColor[q.world] : ""
    return c ? c : "#5bc98c"
  }

  property var panStack: []
  readonly property int rightWeight: {
    var s = 0
    for (var i = 0; i < panStack.length; i++) s += panStack[i]
    return s
  }
  readonly property bool balanced: phase === "play" && rightWeight === answer && answer > 0
  readonly property int diff: rightWeight - answer

  property string phase: "play"   // play | won
  property int overshoots: 0

  onQChanged: reset()
  Component.onCompleted: reset()
  function reset() {
    phase = "play"
    overshoots = 0
    panStack = []
  }

  function addPiece(v) {
    if (phase !== "play") return
    var s = panStack.slice()
    s.push(v)
    s.sort(function (x, y) { return y - x })   // big blocks first
    panStack = s
    if (rightWeight > answer) overshoots += 1
  }
  function removePiece(i) {
    if (phase !== "play" || i < 0 || i >= panStack.length) return
    var s = panStack.slice()
    s.splice(i, 1)
    panStack = s
  }
  // dev/harness
  function devBalance() {
    reset()
    var left = answer
    var s = []
    while (left >= 10) { s.push(10); left -= 10 }
    while (left >= 5) { s.push(5); left -= 5 }
    while (left >= 1) { s.push(1); left -= 1 }
    panStack = s
  }
  function devTakeOne() { addPiece(1) }

  onBalancedChanged: if (balanced) winTimer.restart()

  Timer {
    id: winTimer
    interval: root.game && root.game.reduceMotion ? 150 : 450
    onTriggered: {
      if (!root.balanced) return
      root.phase = "won"
      confetti.burst()
      root.game.submit(root.answer)
      nextTimer.restart()
    }
  }
  Timer {
    id: nextTimer
    interval: root.game && root.game.reduceMotion ? 400 : 1100
    onTriggered: root.game.next()
  }

  Keys.onEscapePressed: root.quit()
  Keys.onPressed: function (event) {
    if (root.phase !== "play") return
    if (event.key === Qt.Key_1) { root.addPiece(1); event.accepted = true }
    else if (event.key === Qt.Key_5) { root.addPiece(5); event.accepted = true }
    else if (event.key === Qt.Key_0) { root.addPiece(10); event.accepted = true }
    else if (event.key === Qt.Key_Backspace && root.panStack.length > 0) {
      root.removePiece(root.panStack.length - 1); event.accepted = true
    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
      if (root.rightWeight < root.answer) root.addPiece(1)
      else if (root.rightWeight > root.answer && root.panStack.length > 0) root.removePiece(root.panStack.length - 1)
      event.accepted = true
    }
  }

  // ---------------------------------------------------------------- layout
  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, 640)
    spacing: Math.round(12 * (game ? game.textScale : 1))

    Item {
      width: parent.width
      height: 30
      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        Repeater {
          model: game ? game.questions.length : 10
          delegate: Rectangle {
            required property int index
            width: 12; height: 12; radius: 6
            color: index < (game ? game.qIndex : 0) ? root.tint
                 : index === (game ? game.qIndex : 0) ? (game ? game.colText : "#edeffb")
                 : Qt.rgba(1, 1, 1, 0.12)
          }
        }
      }
      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 34; radius: 17
        color: quitMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
        Text { anchors.centerIn: parent; text: "✕"; color: game ? game.colMuted : "#9aa2c8"; font.pixelSize: 15 }
        MouseArea { id: quitMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.quit() }
      }
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: {
        if (root.phase === "won") return "Balanced! 🎉"
        if (root.diff > 0) return "Too much — take some off"
        if (root.diff === 0 && root.rightWeight > 0) return "…"
        return "Build the answer to balance the scale"
      }
      color: root.phase === "won" ? (game ? game.colCorrect : "#63d0a0")
           : root.diff > 0 ? (game ? game.colWrong : "#f4a6c0")
           : (game ? game.colText : "#edeffb")
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(21 * (game ? game.textScale : 1))
      font.bold: true
    }

    // ---- the scale --------------------------------------------------
    Item {
      id: scale
      width: parent.width
      height: Math.round(250 * (game ? game.textScale : 1))

      readonly property real tilt: Math.max(-11, Math.min(11, root.diff * 3.2))
      readonly property real pivotY: height * 0.42

      Rectangle {
        width: 12
        height: parent.height - parent.pivotY
        radius: 4
        color: Qt.rgba(1, 1, 1, 0.16)
        x: parent.width / 2 - 6
        y: parent.pivotY
      }
      Canvas {
        id: fulcrum
        width: 46; height: 32
        x: parent.width / 2 - 23
        y: parent.pivotY
        Connections { target: root; function onTintChanged() { fulcrum.requestPaint() } }
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          ctx.fillStyle = root.tint
          ctx.beginPath()
          ctx.moveTo(width / 2, 0); ctx.lineTo(width, height); ctx.lineTo(0, height)
          ctx.closePath(); ctx.fill()
        }
      }

      Rectangle {
        id: beam
        width: Math.min(parent.width * 0.74, 440)
        height: 14
        radius: 7
        color: root.tint
        x: parent.width / 2 - width / 2
        y: scale.pivotY - height / 2
        transformOrigin: Item.Center
        rotation: scale.tilt
        Behavior on rotation {
          enabled: !(game && game.reduceMotion)
          NumberAnimation { duration: 340; easing.type: Easing.OutBack }
        }

        BalancePan {
          x: -width / 2 + beam.height / 2
          y: beam.height
          counterRotation: -beam.rotation
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          fontFamily: game ? game.fontFamily : "sans-serif"
          cardLabel: root.q ? root.q.text : ""
        }
        BalancePan {
          id: rightPan
          x: beam.width - width / 2 - beam.height / 2
          y: beam.height
          counterRotation: -beam.rotation
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          pieces: root.panStack
          removable: root.phase === "play"
          dropActive: root.phase === "play"
          highlight: root.balanced || root.phase === "won"
          onPieceTapped: function (i) { root.removePiece(i) }
        }
      }
    }

    // ---- the palette: 10s, 5s, 1s -------------------------------
    PvPalette {
      id: pvPalette
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.phase === "play"
      tint: root.tint
      reduceMotion: game ? game.reduceMotion : false
      targetArea: rightPan.dropArea
      onPick: function (v) { root.addPiece(v) }
    }

    Mascot {
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: 50
      implicitHeight: 50
      reduceMotion: game ? game.reduceMotion : false
      bodyColor: root.tint
      mood: root.phase === "won" ? "happy" : root.diff > 0 ? "oops" : "idle"
    }
  }

  Confetti {
    id: confetti
    anchors.fill: parent
    z: 20
    reduceMotion: game ? game.reduceMotion : false
    colors: game ? [game.colCorrect, game.colAccent, game.colStar, root.tint, "#c98adf"]
                 : ["#63d0a0", "#7aa2f7", "#ffce54", "#5bc98c", "#c98adf"]
  }
}
