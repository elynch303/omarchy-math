import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Milestone 0 spike. Exercises every platform assumption the real game
// depends on:
//   - a "panel" kind that a third-party plugin can render as a FloatingWindow
//   - qs.Commons theme tokens (Color / Style) reaching a third-party surface
//   - the shell open()/close()/opened lifecycle contract
//   - persistent state via Quickshell.Io FileView under ~/.local/state
//
// Not the game. This file is replaced in Milestone 1.
Item {
  id: root

  // ---- host injections (see shell.qml panel Instantiator) ----------------
  property var shell: null
  property var manifest: null

  readonly property string pluginId: (manifest && manifest.id) || "io.github.elynch303.kids-math"
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/plugins/" + pluginId
  readonly property string statePath: stateDir + "/spike.json"

  // ---- lifecycle --------------------------------------------------------
  property bool opened: false
  property bool closingFromHost: false

  // ---- persisted spike state ------------------------------------------
  property int launches: 0
  property string lastOpened: "never"
  property bool stateReady: false
  property bool pendingOpen: false

  function open(payloadJson) {
    console.log("[kids-math] open() payload=" + payloadJson)
    root.closingFromHost = false
    root.opened = true
    root.recordOpen()
    Qt.callLater(function () { keyCatcher.forceActiveFocus() })
  }

  // Host-initiated close (`omarchy-shell shell hide`).
  function close() {
    root.closingFromHost = true
    root.opened = false
    root.closingFromHost = false
  }

  // User-initiated close (Esc, window close button) — tell the shell so its
  // openPanelIds map stays consistent and the next toggle works.
  function requestClose() {
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
    else root.close()
  }

  // Records one open. If the persisted state hasn't loaded yet, queue it and
  // flush once applyState() runs, so a fast toggle can't race the file read
  // and get overwritten back to disk's value.
  function recordOpen() {
    if (!root.stateReady) {
      console.log("[kids-math] recordOpen deferred (state not ready)")
      root.pendingOpen = true
      return
    }
    root.launches += 1
    root.lastOpened = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
    console.log("[kids-math] recordOpen -> launches=" + root.launches + " path=" + root.statePath)
    stateFile.setText(JSON.stringify({
      launches: root.launches,
      lastOpened: root.lastOpened
    }, null, 2) + "\n")
  }

  function applyState(raw) {
    console.log("[kids-math] applyState raw=" + JSON.stringify(raw))
    try {
      var data = JSON.parse(raw)
      root.launches = data.launches || 0
      root.lastOpened = data.lastOpened || "never"
    } catch (e) {
      // first run / empty file — keep defaults
    }
    root.stateReady = true
    if (root.pendingOpen) {
      root.pendingOpen = false
      root.recordOpen()
    }
  }

  Component.onCompleted: {
    console.log("[kids-math] Panel loaded, mkdir " + root.stateDir)
    mkdirProc.running = true
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyState(text())
    onLoadFailed: root.applyState("{}")
  }

  FloatingWindow {
    id: window
    title: "Kids Math (spike)"
    color: Color.background
    implicitWidth: 640
    implicitHeight: 480
    minimumSize: Qt.size(420, 360)
    visible: root.opened

    // Only a user-driven close (window button) should tell the shell; our own
    // open()/close() already keep openPanelIds in sync.
    onVisibleChanged: {
      if (!visible && root.opened && !root.closingFromHost) root.requestClose()
    }

    FocusScope {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          root.requestClose()
          event.accepted = true
        }
      }

      Column {
        anchors.centerIn: parent
        width: parent.width - Style.space(64)
        spacing: Style.space(14)

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "+  Kids Math  ÷"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.displayLarge
          font.bold: true
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: "Milestone 0 spike — checking theme tokens, FloatingWindow, and persistence."
          color: Color.foreground
          opacity: 0.7
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "Opened " + root.launches + " time(s)"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "Last opened: " + root.lastOpened + "  —  should survive a shell restart"
          color: Color.foreground
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WrapAnywhere
          text: root.statePath
          color: Color.foreground
          opacity: 0.4
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Button {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Close (Esc)"
          bordered: true
          focusable: true
          onClicked: root.requestClose()
        }
      }
    }
  }
}
