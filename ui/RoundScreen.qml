import QtQuick
import "../logic/progression.js" as Progression

FocusScope {
  id: root
  property var game
  signal quit()

  focus: visible
  onVisibleChanged: if (visible) forceActiveFocus()

  readonly property var q: (game && game.questions.length > game.qIndex) ? game.questions[game.qIndex] : null
  property string phase: "asking"          // asking | revealed
  property int chosen: -1                   // value the kid picked
  property int cursor: -1                   // keyboard cursor over the 4 tiles

  onQChanged: { phase = "asking"; chosen = -1; cursor = -1 }

  function choose(value) {
    if (root.phase !== "asking" || !root.q) return
    root.chosen = value
    root.game.submit(value)
    root.phase = "revealed"
    advanceTimer.restart()
  }

  function proceed() {
    advanceTimer.stop()
    root.game.next()
  }

  Timer {
    id: advanceTimer
    interval: root.q && root.chosen === root.q.answer ? 850 : 1500
    onTriggered: root.proceed()
  }

  Keys.onEscapePressed: root.quit()
  Keys.onPressed: function (event) {
    if (root.phase === "revealed") {
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
        root.proceed(); event.accepted = true
      }
      return
    }
    if (!root.q) return
    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
      root.choose(root.q.choices[event.key - Qt.Key_1]); event.accepted = true
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
      root.cursor = root.cursor <= 0 ? 3 : root.cursor - 1; event.accepted = true
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
      root.cursor = root.cursor < 0 ? 0 : (root.cursor + 1) % 4; event.accepted = true
    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && root.cursor >= 0) {
      root.choose(root.q.choices[root.cursor]); event.accepted = true
    }
  }

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 640)
    spacing: Math.round(22 * (game ? game.textScale : 1))

    // ---- top bar: progress + streak + quit ---------------------------
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
            color: index < (game ? game.qIndex : 0) ? (game ? game.colAccent : "#7aa2f7")
                 : index === (game ? game.qIndex : 0) ? (game ? game.colText : "#edeffb")
                 : Qt.rgba(1, 1, 1, 0.12)
          }
        }
      }

      Text {
        anchors.centerIn: parent
        visible: game && game.streak >= 2
        text: "🔥 " + (game ? game.streak : 0)
        color: game ? game.colStar : "#ffce54"
        font.family: game ? game.fontFamily : "sans-serif"
        font.pixelSize: Math.round(18 * (game ? game.textScale : 1))
        font.bold: true
      }

      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 34; radius: 17
        color: quitMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
        Text { anchors.centerIn: parent; text: "✕"; color: game ? game.colMuted : "#9aa2c8"; font.pixelSize: 15 }
        MouseArea {
          id: quitMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.quit()
        }
      }
    }

    // ---- the question ----------------------------------------------
    Rectangle {
      width: parent.width
      height: Math.round(150 * (game ? game.textScale : 1))
      radius: 20
      color: game ? game.colSurface : "#2b2f42"
      border.width: 2
      border.color: Qt.rgba(1, 1, 1, 0.06)

      Text {
        anchors.centerIn: parent
        text: root.q ? (root.q.text + " = ?") : ""
        color: game ? game.colText : "#edeffb"
        font.family: game ? game.fontFamily : "sans-serif"
        font.pixelSize: Math.round(Math.min(parent.width * 0.12, 64) * (game ? game.textScale : 1))
        font.bold: true
      }
    }

    // ---- feedback line -------------------------------------------
    Item {
      width: parent.width
      height: Math.round(26 * (game ? game.textScale : 1))
      Text {
        anchors.centerIn: parent
        visible: root.phase === "revealed"
        text: {
          if (!root.q) return ""
          if (root.chosen === root.q.answer) return pickPraise()
          return "It's " + root.q.answer + ".  " + root.q.text + " = " + root.q.answer
        }
        color: root.q && root.chosen === root.q.answer
               ? (game ? game.colCorrect : "#63d0a0")
               : (game ? game.colMuted : "#9aa2c8")
        font.family: game ? game.fontFamily : "sans-serif"
        font.pixelSize: Math.round(19 * (game ? game.textScale : 1))
        font.bold: true
      }
    }

    // ---- answer tiles (2x2) -------------------------------------
    Grid {
      width: parent.width
      columns: 2
      spacing: 14

      Repeater {
        model: root.q ? root.q.choices : []
        delegate: AnswerButton {
          required property var modelData
          required property int index
          width: (parent.width - 14) / 2
          height: Math.round(88 * (game ? game.textScale : 1))
          label: modelData
          hotkey: index + 1
          fontFamily: game ? game.fontFamily : "sans-serif"
          textScale: game ? game.textScale : 1
          reduceMotion: game ? game.reduceMotion : false
          surface: game ? game.colSurface : "#2b2f42"
          surfaceAlt: game ? game.colSurfaceAlt : "#363b54"
          textColor: game ? game.colText : "#edeffb"
          accent: game ? game.colAccent : "#7aa2f7"
          correctColor: game ? game.colCorrect : "#63d0a0"
          wrongColor: game ? game.colWrong : "#f4a6c0"
          enabled: root.phase === "asking"
          phase: {
            if (root.phase === "asking") return root.cursor === index ? "cursor" : "idle"
            if (root.q && modelData === root.q.answer) return "correct"
            if (modelData === root.chosen) return "wrong"
            return "dim"
          }
          onPicked: root.choose(modelData)
        }
      }
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: root.phase === "revealed"
      text: "tap or press Enter to keep going"
      color: game ? game.colMuted : "#9aa2c8"
      opacity: 0.7
      font.family: game ? game.fontFamily : "sans-serif"
      font.pixelSize: Math.round(13 * (game ? game.textScale : 1))
    }
  }

  // full-surface catcher so a tap anywhere continues after the reveal
  MouseArea {
    anchors.fill: parent
    enabled: root.phase === "revealed"
    onClicked: root.proceed()
    z: -1
  }

  function pickPraise() {
    var options = ["Yes!", "Nice!", "Got it!", "Great!", "Boom!", "Spot on!"]
    return options[(game ? game.qIndex : 0) % options.length]
  }
}
