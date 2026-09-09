import QtQuick
import "logic/problems.js" as Problems
import "logic/progression.js" as Progression
import "logic/store.js" as Store
import "ui"

// The whole game, with zero Omarchy/Quickshell dependency so it also runs under
// a plain `qml` harness for screenshots. Panel.qml wraps this, overrides the
// palette with live theme tokens, and persists `progress` to disk.
Item {
  id: game
  focus: true

  // ---- palette (defaults = self-contained bright kid theme) --------------
  property color colBg: "#1f2230"
  property color colSurface: "#2b2f42"
  property color colSurfaceAlt: "#363b54"
  property color colText: "#edeffb"
  property color colMuted: "#9aa2c8"
  property color colAccent: "#7aa2f7"
  property color colCorrect: "#63d0a0"
  property color colWrong: "#f4a6c0"
  property color colStar: "#ffce54"
  property string fontFamily: "sans-serif"
  property real textScale: 1.0
  property bool reduceMotion: false

  // World accent colours — always bright regardless of desktop theme.
  readonly property var worldColor: ({
    "add": "#5bc98c", "sub": "#5aa9f0", "mul": "#f0a24a", "div": "#c98adf"
  })

  // ---- host bridge ------------------------------------------------------
  property var progress: Store.emptyProgress()
  signal persist(var nextProgress)     // "please write this to disk"
  signal requestClose()

  // ---- navigation / round state --------------------------------------
  property string screen: "levels"     // levels | round | result
  property string world: "add"
  property int level: 1
  property var questions: []
  property int qIndex: 0
  property int correctCount: 0
  property int streak: 0
  property int bestStreak: 0
  property int lastStars: 0

  readonly property var meta: Progression.WORLD_META[world]

  function openWorld(w) {
    game.world = w
    game.level = Progression.suggestedLevel(game.progress, w)
    game.screen = "levels"
  }

  function startLevel(lv) {
    game.level = lv
    game.questions = Problems.buildRound(game.world, lv, Progression.ROUND_SIZE)
    game.qIndex = 0
    game.correctCount = 0
    game.streak = 0
    game.bestStreak = 0
    game.screen = "round"
  }

  // Returns true if `value` was right. Updates score + streak.
  function submit(value) {
    var q = game.questions[game.qIndex]
    var right = value === q.answer
    if (right) {
      game.correctCount += 1
      game.streak += 1
      game.bestStreak = Math.max(game.bestStreak, game.streak)
    } else {
      game.streak = 0
    }
    return right
  }

  function next() {
    if (game.qIndex + 1 >= game.questions.length) finish()
    else game.qIndex += 1
  }

  function finish() {
    game.lastStars = Progression.starsFor(game.correctCount, game.questions.length)
    var updated = Store.recordRound(game.progress, game.world, game.level,
                                    game.correctCount, game.questions.length, game.lastStars)
    game.progress = updated
    game.persist(updated)
    game.screen = "result"
  }

  function replay() { startLevel(game.level) }

  function nextLevel() {
    var lv = game.level + 1
    if (Progression.isUnlocked(game.progress, game.world, lv)) startLevel(lv)
    else game.screen = "levels"
  }

  Rectangle { anchors.fill: parent; color: game.colBg }

  LevelSelect {
    id: levelScreen
    anchors.fill: parent
    visible: game.screen === "levels"
    enabled: visible
    game: game
    onPlay: function (lv) { game.startLevel(lv) }
    onClose: game.requestClose()
  }

  RoundScreen {
    id: roundScreen
    anchors.fill: parent
    visible: game.screen === "round"
    enabled: visible
    game: game
    onQuit: game.screen = "levels"
  }

  ResultScreen {
    id: resultScreen
    anchors.fill: parent
    visible: game.screen === "result"
    enabled: visible
    game: game
    onPlayAgain: game.replay()
    onNextLevel: game.nextLevel()
    onBackToLevels: game.screen = "levels"
  }
}
