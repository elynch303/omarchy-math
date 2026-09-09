import QtQuick
import "../logic/progression.js" as Progression

// Hands-on round for the intro levels (add/sub, levels 1-3). Kids drag groups
// of blocks together (addition) or drag blocks into the bin (subtraction),
// watch them count, then tap the total. Same Game round state as RoundScreen,
// so scoring / streak / stars are unchanged.
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
  readonly property int total: q ? q.answer : 0
  readonly property color tint: {
    var c = (game && game.worldColor && q) ? game.worldColor[q.world] : ""
    return c ? c : "#5bc98c"
  }

  // play  -> drag things around
  // count -> blocks count themselves up
  // confirm -> tap the total
  // done -> feedback, then advance
  property string phase: "play"
  property int countShown: 0
  property int chosen: -1

  // addition: which groups have been poured into the basket
  property bool pouredA: false
  property bool pouredB: false
  readonly property int basketCount: (pouredA ? a : 0) + (pouredB ? b : 0)
  // subtraction: how many blocks sent to the bin
  property int removed: 0

  onQChanged: root.reset()
  function reset() {
    phase = "play"; countShown = 0; chosen = -1
    pouredA = false; pouredB = false; removed = 0
  }

  // called by the drop handlers (and by dev/shoot.qml)
  function pourGroup(which) {
    if (phase !== "play") return
    if (which === "A") pouredA = true
    else if (which === "B") pouredB = true
    if (basketCount === total) startCount()
  }
  function sendToBin() {
    if (phase !== "play" || removed >= b) return
    removed += 1
    if (removed === b) startCount()
  }

  function startCount() {
    phase = "count"
    countShown = 0
    countTimer.restart()
  }
  function pick(value) {
    if (phase !== "confirm") return
    chosen = value
    var right = game.submit(value)
    phase = "done"
    if (right) confetti.burst()
    doneTimer.restart()
  }
  function proceed() { doneTimer.stop(); game.next() }

  Timer {
    id: countTimer
    interval: 260
    repeat: true
    onTriggered: {
      root.countShown += 1
      if (root.countShown >= root.total) { stop(); root.phase = "confirm" }
    }
  }
  Timer {
    id: doneTimer
    interval: root.chosen === root.total ? 900 : 1500
    onTriggered: root.proceed()
  }

  Keys.onEscapePressed: root.quit()
  Keys.onPressed: function (event) {
    if (root.phase === "confirm" && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
      var opts = root.confirmOptions
      if (event.key - Qt.Key_1 < opts.length) root.pick(opts[event.key - Qt.Key_1])
      event.accepted = true
    } else if (root.phase === "done" && (event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
      root.proceed(); event.accepted = true
    }
  }

  // three gentle numbers for the confirm step (answer plus close neighbours).
  readonly property var confirmOptions: {
    if (!q) return []
    var near = [root.total - 1, root.total + 1, root.total - 2, root.total + 2]
    var out = [root.total]
    for (var i = 0; i < near.length && out.length < 3; i++)
      if (near[i] >= 0 && out.indexOf(near[i]) === -1) out.push(near[i])
    var shift = game ? game.qIndex % out.length : 0
    return out.slice(shift).concat(out.slice(0, shift))
  }

  // ---------------------------------------------------------------- layout
  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 56, 640)
    spacing: Math.round(18 * (game ? game.textScale : 1))

    // top bar: progress dots + quit
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

    // instruction
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: {
        if (root.phase === "count") return "Let's count…"
        if (root.phase === "confirm") return "How many now?"
        if (root.phase === "done") return root.chosen === root.total ? "You got it!" : ("It's " + root.total)
        return root.isAdd ? "Drag the blocks together" : ("Drag " + root.b + " block" + (root.b === 1 ? "" : "s") + " to the bin")
      }
      color: root.phase === "done" && root.chosen === root.total ? (game ? game.colCorrect : "#63d0a0")
           : (game ? game.colText : "#edeffb")
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(22 * (game ? game.textScale : 1))
      font.bold: true
    }

    // the equation, small, as a reference
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.q ? root.q.text + " = " + (root.phase === "done" ? root.total : "?") : ""
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(17 * (game ? game.textScale : 1))
    }

    // ---- play area -------------------------------------------------
    Item {
      id: stage
      width: parent.width
      height: Math.round(224 * (game ? game.textScale : 1))

      // ===== the counting / result tray (shared by both modes) =====
      Column {
        anchors.centerIn: parent
        spacing: 10
        visible: root.phase === "count" || root.phase === "confirm" || root.phase === "done"

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          // Shown while counting and after answering — hidden during "confirm"
          // so the kid counts the blocks rather than reading the number.
          text: root.phase === "count" ? root.countShown
              : root.phase === "done" ? root.total : " "
          color: root.tint
          font.family: game ? game.fontFamily : "sans-serif"
          font.pixelSize: Math.round(64 * (game ? game.textScale : 1))
          font.bold: true
        }
        Grid {
          anchors.horizontalCenter: parent.horizontalCenter
          columns: Math.min(10, root.total)
          spacing: 6
          Repeater {
            model: root.total
            delegate: Block {
              required property int index
              tint: root.tint
              lit: root.phase !== "count" || index < root.countShown
              reduceMotion: game ? game.reduceMotion : false
            }
          }
        }
      }

      // ===== ADDITION: two draggable groups + a basket =====
      Item {
        anchors.fill: parent
        visible: root.isAdd && root.phase === "play"

        DropArea {
          id: basket
          width: parent.width * 0.66
          height: 104
          anchors.horizontalCenter: parent.horizontalCenter
          y: parent.height - height - 4
          onDropped: function (drop) {
            root.pourGroup(drop.keys.length > 0 ? drop.keys[0] : "")
            drop.accept()
          }
          keys: ["A", "B"]
          Rectangle {
            anchors.fill: parent
            radius: 16
            color: basket.containsDrag ? Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.18) : Qt.rgba(1, 1, 1, 0.05)
            border.width: 2
            border.color: basket.containsDrag ? root.tint : Qt.rgba(1, 1, 1, 0.12)
            Text {
              anchors.centerIn: parent
              text: "drop here"
              color: game ? game.colMuted : "#9aa2c8"
              opacity: 0.7
              font.family: game ? game.fontFamily : "sans-serif"
              font.pixelSize: 14
            }
          }
        }

        BlockGroup {
          id: groupA
          groupId: "A"
          count: root.a
          tint: root.tint
          poured: root.pouredA
          reduceMotion: game ? game.reduceMotion : false
          x: parent.width * 0.06
          y: 8
          homeX: x; homeY: y
        }
        BlockGroup {
          id: groupB
          groupId: "B"
          count: root.b
          tint: root.tint
          poured: root.pouredB
          reduceMotion: game ? game.reduceMotion : false
          x: parent.width * 0.9 - width
          y: 8
          homeX: x; homeY: y
        }
      }

      // ===== SUBTRACTION: a tray of blocks + a bin =====
      Item {
        anchors.fill: parent
        visible: !root.isAdd && root.phase === "play"

        DropArea {
          id: bin
          width: 130
          height: 150
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          onDropped: function (drop) {
            if (root.removed < root.b) { root.sendToBin(); drop.accept() }
          }
          Rectangle {
            anchors.fill: parent
            radius: 16
            color: bin.containsDrag && root.removed < root.b
                   ? Qt.rgba(0.95, 0.5, 0.55, 0.2) : Qt.rgba(1, 1, 1, 0.05)
            border.width: 2
            border.color: Qt.rgba(0.95, 0.55, 0.6, 0.5)
            Column {
              anchors.centerIn: parent
              spacing: 4
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🗑"; font.pixelSize: 34 }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.removed + " / " + root.b
                color: game ? game.colMuted : "#9aa2c8"
                font.family: game ? game.fontFamily : "sans-serif"
                font.pixelSize: 15
                font.bold: true
              }
            }
          }
        }

        Grid {
          id: subTray
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: parent.width * 0.04
          width: parent.width * 0.6
          columns: Math.min(5, root.a)
          spacing: 8
          Repeater {
            model: root.a
            delegate: DraggableBlock {
              required property int index
              tint: root.tint
              reduceMotion: game ? game.reduceMotion : false
              gone: index >= (root.a - root.removed)   // last `removed` blocks vanish
              targetArea: bin
              onDroppedOnTarget: root.sendToBin()
            }
          }
        }
      }
    }

    // ---- confirm buttons ------------------------------------------
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14
      visible: root.phase === "confirm"
      Repeater {
        model: root.confirmOptions
        delegate: Rectangle {
          required property var modelData
          required property int index
          width: Math.round(84 * (game ? game.textScale : 1))
          height: Math.round(84 * (game ? game.textScale : 1))
          radius: 18
          color: numMouse.containsMouse ? (game ? game.colSurfaceAlt : "#363b54") : (game ? game.colSurface : "#2b2f42")
          border.width: 2
          border.color: numMouse.containsMouse ? root.tint : Qt.rgba(1, 1, 1, 0.1)
          scale: numMouse.pressed ? 0.96 : 1
          Behavior on scale { enabled: !(game && game.reduceMotion); NumberAnimation { duration: 90 } }
          Text {
            anchors.centerIn: parent
            text: modelData
            color: game ? game.colText : "#edeffb"
            font.family: game ? game.fontFamily : "sans-serif"
            font.pixelSize: Math.round(34 * (game ? game.textScale : 1))
            font.bold: true
          }
          MouseArea {
            id: numMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pick(modelData)
          }
        }
      }
    }

    Mascot {
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: 60
      implicitHeight: 60
      reduceMotion: game ? game.reduceMotion : false
      bodyColor: root.phase === "done" && root.chosen !== root.total
                 ? (game ? game.colWrong : "#f4a6c0") : root.tint
      mood: {
        if (root.phase === "done") return root.chosen === root.total ? "happy" : "oops"
        if (root.phase === "count") return "think"
        return "idle"
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.phase === "done"
    onClicked: root.proceed()
    z: -1
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
