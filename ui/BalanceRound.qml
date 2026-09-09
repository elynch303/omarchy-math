import QtQuick

// Balance-scale round for the intro levels (add/sub, levels 1-2).
//
// Addition "3 + 4": the left pan is loaded with 3 + 4 blocks. The kid drags
//   blocks onto the right pan until the beam is level.
// Subtraction "8 - 3": left pan has 8, right pan starts with 3; the kid adds
//   blocks to the right until it balances (3 + ? = 8).
//
// No answer to pick — you discover it by balancing. Overshoot tips the beam;
// tap a block on the right pan to take it back off.
FocusScope {
  id: root
  property var game
  signal quit()

  focus: visible
  onVisibleChanged: if (visible) forceActiveFocus()

  readonly property var q: (game && game.questions.length > game.qIndex) ? game.questions[game.qIndex] : null
  readonly property bool isAdd: q ? q.world === "add" : true
  readonly property int a: q ? q.operands[0] : 0
  readonly property int b: q ? q.operands[1] : 0
  readonly property int answer: q ? q.answer : 0
  readonly property color tint: {
    var c = (game && game.worldColor && q) ? game.worldColor[q.world] : ""
    return c ? c : "#5bc98c"
  }

  readonly property int leftWeight: isAdd ? (a + b) : a
  readonly property int startRight: isAdd ? 0 : b
  readonly property int added: pool ? pool.taken : 0
  readonly property int rightWeight: startRight + added
  readonly property bool balanced: phase === "play" && rightWeight === leftWeight
  readonly property int poolSize: leftWeight + 3

  property string phase: "play"   // play | won
  property int overshoots: 0

  onQChanged: reset()
  Component.onCompleted: reset()
  function reset() {
    phase = "play"
    overshoots = 0
    if (pool) pool.rebuild()
  }

  // dev/harness helpers
  function devTakeOne() { if (pool) pool.takeLast() }
  function devBalance() {
    var guard = 0
    while (rightWeight < leftWeight && pool && guard++ < 60) pool.takeLast()
  }

  onBalancedChanged: if (balanced) winTimer.restart()
  onRightWeightChanged: if (phase === "play" && rightWeight > leftWeight) root.overshoots += 1

  Timer {
    id: winTimer
    interval: root.game && root.game.reduceMotion ? 150 : 450
    onTriggered: {
      if (!root.balanced) return
      root.phase = "won"
      confetti.burst()
      root.game.submit(root.answer)   // balancing IS the answer
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
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
      // keyboard fallback: nudge toward balance
      if (root.rightWeight < root.leftWeight && pool) pool.takeLast()
      else if (root.rightWeight > root.leftWeight && pool) pool.giveBack()
      event.accepted = true
    } else if (event.key === Qt.Key_Backspace && pool) {
      pool.giveBack(); event.accepted = true
    }
  }

  // ---------------------------------------------------------------- layout
  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 48, 640)
    spacing: Math.round(12 * (game ? game.textScale : 1))

    // top bar
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
        if (root.rightWeight > root.leftWeight) return "Too many — take some off"
        if (root.rightWeight === root.leftWeight) return "…"
        return root.isAdd ? "Add blocks to balance the scale"
                          : "Fill the other side to match"
      }
      color: root.phase === "won" ? (game ? game.colCorrect : "#63d0a0")
           : root.rightWeight > root.leftWeight ? (game ? game.colWrong : "#f4a6c0")
           : (game ? game.colText : "#edeffb")
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(21 * (game ? game.textScale : 1))
      font.bold: true
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.q ? (root.q.text + " = " + (root.phase === "won" ? root.answer : "?")) : ""
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(16 * (game ? game.textScale : 1))
    }

    // ---- the scale --------------------------------------------------
    Item {
      id: scale
      width: parent.width
      height: Math.round(228 * (game ? game.textScale : 1))

      readonly property real diff: root.rightWeight - root.leftWeight
      readonly property real tilt: Math.max(-11, Math.min(11, diff * 3.2))
      readonly property real pivotY: height * 0.46   // beam's centre of rotation

      // stand
      Rectangle {
        width: 12
        height: parent.height - parent.pivotY
        radius: 4
        color: Qt.rgba(1, 1, 1, 0.16)
        x: parent.width / 2 - 6
        y: parent.pivotY
      }
      // fulcrum triangle, apex at the pivot
      Canvas {
        width: 46; height: 34
        x: parent.width / 2 - 23
        y: parent.pivotY
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          ctx.fillStyle = root.tint
          ctx.beginPath()
          ctx.moveTo(width / 2, 0)
          ctx.lineTo(width, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fill()
        }
      }

      // beam
      Rectangle {
        id: beam
        width: Math.min(parent.width * 0.72, 420)
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
          id: leftPan
          x: -width / 2 + beam.height / 2
          y: beam.height
          counterRotation: -beam.rotation
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          count: root.leftWeight
          split: root.isAdd ? root.a : -1
        }
        BalancePan {
          id: rightPan
          x: beam.width - width / 2 - beam.height / 2
          y: beam.height
          counterRotation: -beam.rotation
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          count: root.rightWeight
          fixedCount: root.startRight
          removable: root.phase === "play"
          dropActive: root.phase === "play"
          highlight: root.balanced
          onRemoveTapped: if (pool) pool.giveBack()
        }
      }
    }

    // ---- the pool ------------------------------------------------
    DragBlockField {
      id: pool
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.phase === "play"
      total: root.poolSize
      takeCount: root.poolSize
      tint: root.tint
      reduceMotion: game ? game.reduceMotion : false
      targetArea: rightPan.dropArea
    }

    Mascot {
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: 52
      implicitHeight: 52
      reduceMotion: game ? game.reduceMotion : false
      bodyColor: root.tint
      mood: root.phase === "won" ? "happy"
          : root.rightWeight > root.leftWeight ? "oops" : "idle"
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
