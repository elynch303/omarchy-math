# Milestone 1 — core game loop (Addition world)

Playable start → stars, for the Addition world. Verified headlessly with a
Qt6 `qml` harness (`dev/shoot.qml`, offscreen) — **no impact on the live desktop.**

## What's in

**Logic (pure JS, dual QML/Node modules):**

- `logic/problems.js` — `generate(world, level, rng)` and `buildRound(...)`.
  Addition levels 1–7: sums to 5 / 10 / 20, 2-digit + 1-digit, no-carry
  2-digit sums, carrying 2-digit sums, three addends. Deterministic PRNG for
  tests. Distractors mix ±1/±2/±10, the subtract-instead trap, and a
  digit-transpose slip; always 4 unique non-negative choices including the
  answer.
- `logic/progression.js` — world metadata, `starsFor` (3 = all, 2 = ≥80%,
  1 = ≥60%), `isUnlocked` (next level opens at ≥2 stars), `suggestedLevel`,
  star tallies.
- `logic/store.js` — progress document load / normalize / serialize /
  `recordRound` (immutable) / `setSetting`.
- `dev/tests/run.mjs` — dependency-free Node runner. **20,025 assertions, all
  green** (`node dev/tests/run.mjs`).

**UI (QtQuick only, theme-agnostic):**

- `Game.qml` — container + navigation + round state. Palette is a set of
  overridable properties (bright kid defaults); `Panel.qml` maps Omarchy
  `Color`/`Style` tokens onto them.
- `ui/LevelSelect.qml` — world title, star pill, level grid with per-level
  stars / blurbs / locks.
- `ui/RoundScreen.qml` — progress dots, streak counter, big question card,
  2×2 answer tiles, gentle reveal (shows the correct answer, never a scary X),
  auto-advance. Keyboard: `1`–`4` pick, arrows move a cursor, Enter/Space
  confirm, Esc leaves.
- `ui/ResultScreen.qml` — animated stars, score, encouraging line, best-streak
  note, Next level / Play again / Back to levels.
- `ui/AnswerButton.qml`, `ui/ResultButton.qml`, `ui/StarRow.qml` — shared bits.

**Shell integration:**

- `Panel.qml` rewritten — `FloatingWindow` hosting `Game`, theme mapping,
  progress persisted to `~/.local/state/omarchy/plugins/<id>/progress.json`
  via `FileView` (same pattern proven in M0).
- `dev/harness.qml` / `dev/shoot.qml` — standalone runners so all future UI
  work can be checked without opening a window on the user's screen.

## Screens

`/tmp/km-1-levels.png`, `/tmp/km-2-round.png`, `/tmp/km-3-result.png` from the
headless run — level select, a live question, and a 2-star result.

## Not yet (per plan)

- Other three worlds (M2)
- Home / world-select screen (M2)
- Persistence wired through the real shell FileView is coded but only
  smoke-tested in M0's spike, not yet re-run end-to-end in-shell (needs a
  scratch-workspace live test)
- Mascot, animations, sounds, grown-ups screen, number-pad, re-queue-on-wrong
  (M3)

## Dev commands

```bash
node dev/tests/run.mjs
/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" -I . Game.qml ui/*.qml
QT_QPA_PLATFORM=offscreen /usr/bin/qml6 dev/shoot.qml    # regenerate screenshots
/usr/bin/qml6 dev/harness.qml                            # interactive, windowed
```

> Note: use the **Qt6** `qml` (`/usr/bin/qml6` or `/usr/lib/qt6/bin/qml`) —
> `/usr/bin/qml` is Qt 5 on this box and won't load anything.
