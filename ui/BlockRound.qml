import QtQuick

// Hands-on round for the intro levels (add/sub, levels 1-3).
//
// Addition: a pool of loose blocks (always the same count for the level, so the
//   pile never gives away the answer). The kid drags `a` blocks into the box,
//   then `b` more, the lid shuts, and they tap how many are inside.
// Subtraction: the box holds `a` blocks; the kid drags `b` out to the bin, the
//   lid shuts on what's left.
// Then the box opens and the blocks count themselves up to check.
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

  // always the same pool size for a level, so the count is no help
  readonly property int poolSize: total <= 10 ? 10 : 20

  // play | merge | closed | reveal | done
  property string phase: "play"
  property int countShown: 0
  property int chosen: -1

  // how many blocks the kid has moved (into the box for add, to the bin for sub)
  readonly property int moved: field ? field.taken : 0
  // addition sub-step: first put in `a`, then `b`
  readonly property bool onSecondStep: isAdd && moved >= a

  onQChanged: root.reset()
  Component.onCompleted: root.reset()
  function reset() {
    phase = "play"; countShown = 0; chosen = -1
    if (field) field.rebuild()
  }

  function onAllMoved() {
    if (moved >= (isAdd ? total : b)) startMerge()
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
    interval: root.game && root.game.reduceMotion ? 150 : 600
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

  function keyStep() {
    if (root.phase !== "play" || !field) return
    var idx = field.present[field.present.length - 1]
    if (idx !== undefined) field.take(idx)
  }

  Keys.onEscapePressed: root.quit()
  Keys.onPressed: function (event) {
    if (root.phase === "play" && (event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
      root.keyStep(); event.accepted = true
    } else if (root.phase === "closed" && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
      var opts = root.confirmOptions
      if (event.key - Qt.Key_1 < opts.length) root.startReveal(opts[event.key - Qt.Key_1])
      event.accepted = true
    } else if (root.phase === "done" && (event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
      root.proceed(); event.accepted = true
    }
  }

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
    spacing: Math.round(14 * (game ? game.textScale : 1))

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
        if (root.phase === "closed") return root.isAdd ? "How many in the box?" : "How many are left?"
        if (root.phase === "reveal") return "Let's check…"
        if (root.phase === "done") return root.chosen === root.total ? "You got it!" : ("It's " + root.total)
        if (root.isAdd) return root.onSecondStep
          ? ("Now put in " + root.b + " more")
          : ("Put " + root.a + " block" + (root.a === 1 ? "" : "s") + " in the box")
        return "Drag " + root.b + " block" + (root.b === 1 ? "" : "s") + " out to the bin"
      }
      color: root.phase === "done" && root.chosen === root.total ? (game ? game.colCorrect : "#63d0a0")
           : (game ? game.colText : "#edeffb")
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(22 * (game ? game.textScale : 1))
      font.bold: true
    }

    // step counter (play only)
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: root.phase === "play"
      text: {
        if (!root.q) return ""
        if (root.isAdd) return root.onSecondStep
          ? ((root.moved - root.a) + " / " + root.b)
          : (root.moved + " / " + root.a)
        return root.moved + " / " + root.b
      }
      color: root.tint
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(18 * (game ? game.textScale : 1))
      font.bold: true
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: root.phase !== "play"
      text: root.q ? (root.q.text + " = " + (root.phase === "done" ? root.total : "?")) : ""
      color: game ? game.colMuted : "#9aa2c8"
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(17 * (game ? game.textScale : 1))
    }

    // ---- stage -----------------------------------------------------
    Item {
      id: stage
      width: parent.width
      height: Math.round(256 * (game ? game.textScale : 1))

      // the box: destination for addition, holder for subtraction, and the
      // count-up display.
      BlockBox {
        id: box
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.72, 380)
        height: root.isAdd ? 112 : Math.max(112, root.subBoxHeight)
        tint: root.tint
        reduceMotion: game ? game.reduceMotion : false
        lidOpen: root.phase !== "closed"

        // subtraction field lives in the box
        DragBlockField {
          id: subFieldHolder
          anchors.centerIn: parent
          visible: !root.isAdd && root.phase === "play"
          total: root.a
          takeCount: root.b
          tint: root.tint
          reduceMotion: game ? game.reduceMotion : false
          targetArea: bin
          onAllTaken: root.onAllMoved()
        }

        // addition drop target
        DropArea {
          id: boxDrop
          anchors.fill: parent
          enabled: root.isAdd && root.phase === "play"
        }

        // count-up (merge / reveal / done)
        Grid {
          anchors.centerIn: parent
          visible: root.phase === "merge" || root.phase === "reveal" || root.phase === "done"
          columns: Math.min(10, Math.max(1, root.total))
          spacing: 5
          Repeater {
            model: root.total
            delegate: Block {
              required property int index
              tint: root.tint
              reduceMotion: game ? game.reduceMotion : false
              lit: root.phase !== "reveal" || index < root.countShown
              width: 24; height: 24
            }
          }
        }

        // a jumbled heap while filling (add) — overlapping, so it can't be
        // counted at a glance
        Item {
          anchors.centerIn: parent
          width: 120; height: 60
          visible: root.isAdd && root.phase === "play" && root.moved > 0
          Repeater {
            model: Math.min(root.moved, 9)
            delegate: Rectangle {
              required property int index
              width: 22; height: 22; radius: 6
              color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.85)
              x: 60 + (index % 3) * 10 - 24 + (index * 7 % 13) - 6
              y: 30 + Math.floor(index / 3) * 8 - 12 + (index * 5 % 11) - 5
              rotation: index * 20 % 40 - 20
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

      // ADDITION: the pool of loose blocks, above the box.
      // Only `a` can be moved until the first step is done, then `b` more.
      DragBlockField {
        id: addFieldHolder
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.isAdd && root.phase === "play"
        total: root.poolSize
        takeCount: root.onSecondStep ? root.total : root.a
        tint: root.tint
        reduceMotion: game ? game.reduceMotion : false
        targetArea: boxDrop
        onAllTaken: root.onAllMoved()
      }

      // SUBTRACTION: the bin, beside the box
      DropArea {
        id: bin
        width: 112
        height: 112
        anchors.right: parent.right
        anchors.verticalCenter: box.verticalCenter
        visible: !root.isAdd && root.phase === "play"
        Rectangle {
          anchors.fill: parent
          radius: 16
          color: bin.containsDrag && root.moved < root.b
                 ? Qt.rgba(0.95, 0.5, 0.55, 0.22) : Qt.rgba(1, 1, 1, 0.05)
          border.width: 2
          border.color: Qt.rgba(0.95, 0.55, 0.6, 0.5)
          Column {
            anchors.centerIn: parent
            spacing: 3
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🗑"; font.pixelSize: 30 }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.moved + " / " + root.b
              color: game ? game.colMuted : "#9aa2c8"
              font.family: game ? game.fontFamily : "sans-serif"
              font.pixelSize: 14
              font.bold: true
            }
          }
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
      implicitWidth: 56
      implicitHeight: 56
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

  // which field is active
  readonly property var field: root.isAdd ? addFieldHolder : subFieldHolder

  readonly property real subBoxHeight: {
    var cols = Math.max(1, Math.min(a <= 12 ? 5 : 7, a))
    var cell = a <= 12 ? 44 : 38
    return Math.ceil(Math.max(1, a) / cols) * cell + 22
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
