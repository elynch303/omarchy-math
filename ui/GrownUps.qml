import QtQuick
import "../logic/progression.js" as Progression

FocusScope {
  id: root
  property var game
  property bool autoEnter: false     // dev/harness only — skips the hold gate
  signal done()

  focus: visible
  onVisibleChanged: {
    if (visible) { forceActiveFocus(); root.entered = root.autoEnter }
    else { root.entered = false; root.confirmReset = false; hold.stop(); holdFill = 0 }
  }
  Keys.onEscapePressed: root.done()

  property bool entered: false
  property bool confirmReset: false
  property real holdFill: 0

  readonly property var g: game

  NumberAnimation {
    id: hold
    target: root; property: "holdFill"; to: 1; duration: 1400
    onFinished: { root.entered = true; root.holdFill = 0 }
  }

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 560)
    spacing: 20

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: "Grown-ups"
      color: g ? g.colText : "#edeffb"
      font.family: g ? g.fontFamily : "sans-serif"
      font.pixelSize: Math.round(30 * (g ? g.textScale : 1))
      font.bold: true
    }

    // ---- gate -------------------------------------------------------
    Column {
      width: parent.width
      spacing: 14
      visible: !root.entered

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "Press and hold the button to open settings and progress."
        color: g ? g.colMuted : "#9aa2c8"
        font.family: g ? g.fontFamily : "sans-serif"
        font.pixelSize: Math.round(15 * (g ? g.textScale : 1))
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 260; height: 56; radius: 16
        color: g ? g.colSurface : "#2b2f42"
        border.width: 2
        border.color: Qt.rgba(1, 1, 1, 0.1)

        Rectangle {
          anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
          width: parent.width * root.holdFill
          radius: parent.radius
          color: Qt.rgba((g ? g.colAccent.r : 0.48), (g ? g.colAccent.g : 0.63), (g ? g.colAccent.b : 0.97), 0.4)
        }
        Text {
          anchors.centerIn: parent
          text: "Hold to enter"
          color: g ? g.colText : "#edeffb"
          font.family: g ? g.fontFamily : "sans-serif"
          font.pixelSize: 17
          font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          onPressed: hold.start()
          onReleased: { if (!root.entered) { hold.stop(); root.holdFill = 0 } }
          onCanceled: { hold.stop(); root.holdFill = 0 }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Back"
        color: g ? g.colMuted : "#9aa2c8"
        font.family: g ? g.fontFamily : "sans-serif"
        font.pixelSize: 15
        MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: root.done() }
      }
    }

    // ---- panel ----------------------------------------------------
    Column {
      width: parent.width
      spacing: 18
      visible: root.entered

      // progress overview
      Column {
        width: parent.width
        spacing: 8
        Text {
          text: "Progress"
          color: g ? g.colMuted : "#9aa2c8"
          font.family: g ? g.fontFamily : "sans-serif"
          font.pixelSize: 13
          font.bold: true
        }
        Repeater {
          model: Progression.WORLD_ORDER
          delegate: Rectangle {
            required property string modelData
            readonly property var meta: Progression.WORLD_META[modelData]
            readonly property int stars: g ? Progression.worldStars(g.progress, modelData) : 0
            readonly property int cleared: {
              if (!g) return 0
              var n = 0
              for (var lv = 1; lv <= meta.levels; lv++) if (Progression.bestStars(g.progress, modelData, lv) > 0) n++
              return n
            }
            width: parent.width
            height: 40
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.04)
            Row {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 10
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: meta.name
                color: g ? g.colText : "#edeffb"
                font.family: g ? g.fontFamily : "sans-serif"
                font.pixelSize: 15
              }
            }
            Text {
              anchors.right: parent.right
              anchors.rightMargin: 14
              anchors.verticalCenter: parent.verticalCenter
              text: cleared + "/" + meta.levels + " levels   ★ " + stars + "/" + Progression.maxStars(modelData)
              color: g ? g.colMuted : "#9aa2c8"
              font.family: g ? g.fontFamily : "sans-serif"
              font.pixelSize: 13
            }
          }
        }
      }

      // settings
      Column {
        width: parent.width
        spacing: 8
        Text {
          text: "Settings"
          color: g ? g.colMuted : "#9aa2c8"
          font.family: g ? g.fontFamily : "sans-serif"
          font.pixelSize: 13
          font.bold: true
        }
        SettingToggle {
          width: parent.width
          game: root.game
          label: "Sound"
          checked: g ? g.soundOn : true
          onToggled: function (v) { root.game.setSetting("sound", v) }
        }
        SettingToggle {
          width: parent.width
          game: root.game
          label: "Reduce motion"
          checked: g ? (g.settings.reduceMotion === true) : false
          locked: g ? g.reduceMotionPref : false
          lockedNote: "on (desktop setting)"
          onToggled: function (v) { root.game.setSetting("reduceMotion", v) }
        }
        SettingToggle {
          width: parent.width
          game: root.game
          label: "Larger text"
          checked: g ? (g.settings.largeText === true) : false
          onToggled: function (v) { root.game.setSetting("largeText", v) }
        }

        // child's age — opens the levels that are too easy for an older kid
        Rectangle {
          width: parent.width
          height: ageCol.implicitHeight + 20
          radius: 12
          color: Qt.rgba(1, 1, 1, 0.04)
          Column {
            id: ageCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8
            Text {
              text: "Child's age"
              color: g ? g.colText : "#edeffb"
              font.family: g ? g.fontFamily : "sans-serif"
              font.pixelSize: 15
            }
            Text {
              text: "Skips levels that are too easy. Lower levels stay playable."
              color: g ? g.colMuted : "#9aa2c8"
              font.family: g ? g.fontFamily : "sans-serif"
              font.pixelSize: 12
            }
            Flow {
              width: parent.width
              spacing: 6
              Repeater {
                model: [0, 5, 6, 7, 8, 9, 10, 11, 12]
                delegate: Rectangle {
                  required property int modelData
                  readonly property bool sel: g && (g.settings.age || 0) === modelData
                  width: modelData === 0 ? 44 : 34
                  height: 34
                  radius: 9
                  color: sel ? (g ? g.colAccent : "#7aa2f7")
                       : ageMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                  Text {
                    anchors.centerIn: parent
                    text: modelData === 0 ? "Off" : modelData
                    color: parent.sel ? "#10131f" : (g ? g.colText : "#edeffb")
                    font.family: g ? g.fontFamily : "sans-serif"
                    font.pixelSize: modelData === 0 ? 13 : 15
                    font.bold: parent.sel
                  }
                  MouseArea {
                    id: ageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.game.setSetting("age", modelData)
                  }
                }
              }
            }
          }
        }
      }

      // reset + done
      Column {
        width: parent.width
        spacing: 10

        Rectangle {
          width: parent.width
          height: 46
          radius: 12
          visible: !root.confirmReset
          color: resetMouse.containsMouse ? Qt.rgba(0.95, 0.4, 0.5, 0.16) : Qt.rgba(1, 1, 1, 0.04)
          border.width: 1
          border.color: Qt.rgba(0.95, 0.5, 0.55, 0.4)
          Text {
            anchors.centerIn: parent
            text: "Reset all progress"
            color: g ? g.colWrong : "#f4a6c0"
            font.family: g ? g.fontFamily : "sans-serif"
            font.pixelSize: 15
          }
          MouseArea {
            id: resetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.confirmReset = true
          }
        }

        Row {
          width: parent.width
          spacing: 10
          visible: root.confirmReset
          Rectangle {
            width: (parent.width - 10) / 2
            height: 46; radius: 12
            color: Qt.rgba(1, 1, 1, 0.06)
            Text { anchors.centerIn: parent; text: "Keep it"; color: g ? g.colText : "#edeffb"; font.pixelSize: 15; font.family: g ? g.fontFamily : "sans-serif" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmReset = false }
          }
          Rectangle {
            width: (parent.width - 10) / 2
            height: 46; radius: 12
            color: Qt.rgba(0.95, 0.4, 0.5, 0.3)
            Text { anchors.centerIn: parent; text: "Erase everything"; color: "#fff"; font.pixelSize: 15; font.family: g ? g.fontFamily : "sans-serif"; font.bold: true }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.confirmReset = false; root.game.resetProgress() }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 46; radius: 12
          color: doneMouse.containsMouse ? (g ? g.colSurfaceAlt : "#363b54") : (g ? g.colSurface : "#2b2f42")
          Text { anchors.centerIn: parent; text: "Done"; color: g ? g.colText : "#edeffb"; font.pixelSize: 16; font.bold: true; font.family: g ? g.fontFamily : "sans-serif" }
          MouseArea {
            id: doneMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.done()
          }
        }
      }
    }
  }
}
