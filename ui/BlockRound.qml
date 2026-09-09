import QtQuick

// Hands-on round for the intro levels (add/sub, levels 1-3).
//
//   play   - drag the two groups into the box (add), or drag blocks out to the
//            bin (sub)
//   merge  - the blocks tumble in and the lid slams shut (short)
//   closed - the box is shut with a "?" ; kid taps how many are inside
//   reveal - the lid opens and the blocks count themselves up
//   done   - mascot reacts, tap / Enter to continue
//
// Shares Game round state, so scoring / streak / stars are unchanged.
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

  property string phase: "play"
  property int countShown: 0
  property int chosen: -1

  property bool pouredA: false
  property bool pouredB: false
  readonly property int inBox: (pouredA ? a : 0) + (pouredB ? b : 0)
  property int removed: 0

  // how tall the box must be to hold the subtraction field
  readonly property real subBoxHeight: {
    var cols = a <= 14 ? 5 : 7
    var cell = a <= 14 ? 44 : 38
    return Math.ceil(Math.max(1, a) / cols) * cell + 22
  }

  onQChanged: root.reset()
  Component.onCompleted: root.reset()
  function reset() {
    phase = "play"; countShown = 0; chosen = -1
    pouredA = false; pouredB = false; removed = 0
    if (subField) subField.rebuild()
  }

  function pourGroup(which) {
    if (phase !== "play") return
    if (which === "A") pouredA = true
    else if (which === "B") pouredB = true
    if (inBox === total) startMerge()
  }

  function startMerge() {
    phase = "merge"
    mergeTimer.restart()
  }
  function startReveal(value) {
    if (phase !== "closed") return
    chosen = value
    var right = game.submit(value)
    phase = "reveal"
    countShown = 0
    countTimer.restart()
    if (right) confetti.burst()
  }
  function proceed() { doneTimer.stop(); game.next() }

  Timer {
    id: mergeTimer
    interval: root.game && root.game.reduceMotion ? 150 : 650
    onTriggered: root.phase = "closed"
  }
  Timer {
    id: countTimer
    interval: 240
    repeat: true
    onTriggered: {
      root.countShown += 1
      if (root.countShown >= root.total) { stop(); root.phase = "done"; doneTimer.restart() }
    }
  }
  Timer {
    id: doneTimer
    interval: root.chosen === root.total ? 1100 : 1700
    onTriggered: root.proceed()
  }

  Keys.onEscapePressed: root.quit()
  Keys.onPressed: function (event) {
    if (root.phase === "closed" && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
      var opts = root.confirmOptions
      if (event.key - Qt.Key_1 < opts.length) root.startReveal(opts[event.key - Qt.Key_1])
      event.accepted = true
    } else if (root.phase === "done" && (event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
      root.proceed(); event.accepted = true
    }
  }

  // gentle numbers for the closed step: the answer plus close neighbours
  readonly property var confirmOptions: {
    if (!q) return []
    var near = [total - 1, total + 1, total - 2, total + 2]
    var out = [total]
    for (var i = 0; i < near.length && out.length < 3; i++)
      if (near[i] >= 0 && out.indexOf(near[i]) === -1) out.push(near[i])
    var shift = game ? game.qIndex % out.length : 0
    return out.slice(shift).concat(out.slice(0, shift))
  }

  // ---------------------------------------------------------------- layout
  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 56, 620)
    spacing: Math.round(16 * (game ? game.textScale : 1))

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
        if (root.phase === "merge") return "…"
        if (root.phase === "closed") return "How many in the box?"
        if (root.phase === "reveal") return "Let's check…"
        if (root.phase === "done") return root.chosen === root.total ? "You got it!" : ("It's " + root.total)
        return root.isAdd ? "Drag both groups into the box"
                          : ("Drag " + root.b + " block" + (root.b === 1 ? "" : "s") + " out to the bin")
      }
      color: root.phase === "done" && root.chosen === root.total ? (game ? game.colCorrect : "#63d0a0")
           : (game ? game.colText : "#edeffb")
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(22 * (game ? game.textScale : 1))
      font.bold: true
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.q ? (root.q.text + " = " + (root.phase === "done" ? root.total : "?")) : ""
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(17 * (game ? game.textScale : 1))
    }

    // ---- stage -----------------------------------------------------
    Item {
      id: stage
      width: parent.width
      height: Math.round(Math.max(258, box.height + 96) * (game ? game.textScale : 1))

      // the box — the subtraction tray, the addition drop target, and the
      // count-up display, depending on phase.
      BlockBox {
        id: box
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.72, 380)
        height: root.isAdd ? 116 : Math.max(116, root.subBoxHeight)
        tint: root.tint
        reduceMotion: game ? game.reduceMotion : false
        // open except while the kid is answering
        lidOpen: root.phase !== "closed"

        // subtraction: the blocks the kid drags OUT sit in the box
        SubBlockField {
          id: subField
          anchors.centerIn: parent
          visible: !root.isAdd && root.phase === "play"
          total: root.a
          toRemove: root.b
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          binArea: bin
          onRemovedChanged: root.removed = removed
          onAllRemoved: root.startMerge()
        }

        // the pile / count-up
        Grid {
          anchors.centerIn: parent
          visible: root.phase === "merge" || root.phase === "reveal" || root.phase === "done"
                   || (root.isAdd && root.inBox > 0)
          columns: Math.min(10, Math.max(1, root.total))
          spacing: 5
          Repeater {
            model: (root.phase === "reveal" || root.phase === "done") ? root.total
                 : root.isAdd ? root.inBox : (root.a - root.removed)
            delegate: Block {
              required property int index
              tint: root.tint
              reduceMotion: game ? game.reduceMotion : false
              lit: root.phase !== "reveal" || index < root.countShown
              width: 26; height: 26
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.top
          anchors.bottomMargin: 4
          visible: root.phase === "reveal" || root.phase === "done"
          text: root.phase === "reveal" ? root.countShown : root.total
          color: root.tint
          font.family: game ? game.fontFamily : "sans-serif"
          font.pixelSize: Math.round(44 * (game ? game.textScale : 1))
          font.bold: true
        }
      }

      // SUBTRACTION: the bin, beside the box
      DropArea {
        id: bin
        width: 112
        height: 116
        anchors.right: parent.right
        anchors.verticalCenter: box.verticalCenter
        visible: !root.isAdd && root.phase === "play"
        Rectangle {
          anchors.fill: parent
          radius: 16
          color: bin.containsDrag && root.removed < root.b
                 ? Qt.rgba(0.95, 0.5, 0.55, 0.22) : Qt.rgba(1, 1, 1, 0.05)
          border.width: 2
          border.color: Qt.rgba(0.95, 0.55, 0.6, 0.5)
          Column {
            anchors.centerIn: parent
            spacing: 3
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🗑"; font.pixelSize: 30 }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.removed + " / " + root.b
              color: game ? game.colMuted : "#9aa2c8"
              font.family: game ? game.fontFamily : "sans-serif"
              font.pixelSize: 14
              font.bold: true
            }
          }
        }
      }

      // ADDITION: drop target over the box + the two draggable groups
      Item {
        id: addArea
        anchors.fill: parent
        visible: root.isAdd && root.phase === "play"

        function place() {
          if (width <= 0) return
          if (!groupA.dragging) { groupA.restX = Math.round(width * 0.12); groupA.restY = 2 }
          if (!groupB.dragging) { groupB.restX = Math.round(width * 0.88 - groupB.width); groupB.restY = 2 }
          groupA.sinkX = box.x + box.width / 2 - groupA.width / 2
          groupA.sinkY = box.y + box.height / 2 - groupA.height / 2
          groupB.sinkX = box.x + box.width / 2 - groupB.width / 2
          groupB.sinkY = box.y + box.height / 2 - groupB.height / 2
        }
        onWidthChanged: place()
        onVisibleChanged: if (visible) place()
        Component.onCompleted: place()
        Connections { target: groupB; function onWidthChanged() { addArea.place() } }

        DropArea {
          anchors.fill: box
          keys: ["A", "B"]
          onDropped: function (drop) {
            root.pourGroup(drop.keys.length > 0 ? drop.keys[0] : "")
            drop.accept()
          }
        }

        BlockGroup {
          id: groupA
          groupId: "A"; count: root.a; tint: root.tint
          poured: root.pouredA
          reduceMotion: game ? game.reduceMotion : false
        }
        BlockGroup {
          id: groupB
          groupId: "B"; count: root.b; tint: root.tint
          poured: root.pouredB
          reduceMotion: game ? game.reduceMotion : false
        }
      }

    }

    // ---- closed: tap how many ------------------------------------
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14
      visible: root.phase === "closed"
      Repeater {
        model: root.confirmOptions
        delegate: Rectangle {
          required property var modelData
          width: Math.round(80 * (game ? game.textScale : 1))
          height: Math.round(80 * (game ? game.textScale : 1))
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
            font.pixelSize: Math.round(32 * (game ? game.textScale : 1))
            font.bold: true
          }
          MouseArea {
            id: numMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.startReveal(modelData)
          }
        }
      }
    }

    Mascot {
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: 58
      implicitHeight: 58
      reduceMotion: game ? game.reduceMotion : false
      bodyColor: root.phase === "done" && root.chosen !== root.total
                 ? (game ? game.colWrong : "#f4a6c0") : root.tint
      mood: {
        if (root.phase === "done") return root.chosen === root.total ? "happy" : "oops"
        if (root.phase === "reveal" || root.phase === "merge") return "think"
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
