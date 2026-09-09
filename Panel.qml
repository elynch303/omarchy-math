import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "logic/store.js" as Store

// Omarchy shell wrapper around Game.qml: owns the window, the theme mapping,
// and progress persistence. The game itself is theme-agnostic and lives in
// Game.qml (which also runs under dev/harness.qml with no shell).
Item {
  id: root

  // ---- host injections -------------------------------------------------
  property var shell: null
  property var manifest: null

  readonly property string pluginId: (manifest && manifest.id) || "io.github.elynch303.kids-math"
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/plugins/" + pluginId
  readonly property string statePath: stateDir + "/progress.json"

  // ---- lifecycle -----------------------------------------------------
  property bool opened: false
  property bool closingFromHost: false

  function open(payloadJson) {
    root.closingFromHost = false
    root.opened = true
    Qt.callLater(function () { game.forceActiveFocus() })
  }

  function close() {
    root.closingFromHost = true
    root.opened = false
    root.closingFromHost = false
  }

  function requestClose() {
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
    else root.close()
  }

  // ---- persistence -------------------------------------------------
  property bool stateReady: false

  Component.onCompleted: mkdirProc.running = true

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: function (exitCode) { progressFile.reload() }
  }

  FileView {
    id: progressFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: { game.progress = Store.parse(text()); root.stateReady = true }
    onLoadFailed: { game.progress = Store.emptyProgress(); root.stateReady = true }
  }

  FloatingWindow {
    id: window
    title: "Kids Math"
    color: game.colBg
    implicitWidth: 900
    implicitHeight: 680
    minimumSize: Qt.size(560, 480)
    visible: root.opened

    onVisibleChanged: {
      if (!visible && root.opened && !root.closingFromHost) root.requestClose()
    }

    Game {
      id: game
      anchors.fill: parent
      focus: true

      // Map Omarchy theme tokens onto the game palette. Keep the game's own
      // bright world/feedback colours (correct/wrong/star) — only the
      // surrounding surfaces follow the desktop theme.
      colBg: Color.background
      colText: Color.foreground
      colMuted: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.6)
      colAccent: Color.accent
      colSurface: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
      colSurfaceAlt: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
      fontFamily: Style.font.family
      textScale: (game.progress && game.progress.settings && game.progress.settings.largeText) ? 1.18 : 1.0
      reduceMotion: (game.progress && game.progress.settings && game.progress.settings.reduceMotion) === true

      onPersist: function (nextProgress) {
        if (root.stateReady) progressFile.setText(Store.serialize(nextProgress))
      }
      onRequestClose: root.requestClose()
    }
  }
}
