# Milestone 3 — polish: grown-ups screen, settings, confetti

Verified headlessly (`dev/shoot.qml`). New screenshot: `/tmp/km-6-grownups.png`.

## What's in

- **`ui/GrownUps.qml`** — reached from a "For grown-ups" link on Home.
  - Press-and-hold gate (1.4 s) so a young kid can't wander in.
  - Progress overview: per world, levels cleared + star tally.
  - Settings toggles: Sound, Reduce motion, Larger text — persisted into the
    progress doc via `store.setSetting`.
  - Reset all progress, with a two-step confirm.
- **`ui/SettingToggle.qml`** — a labelled switch row; supports a `locked` state
  (e.g. reduce-motion forced on by the desktop) with a note.
- **`ui/Confetti.qml`** — dependency-free burst of coloured bits on a correct
  answer. No-ops when motion is reduced.
- **Streak meter** — the round screen's streak indicator now has a fill bar.
- **Settings plumbing** — `Game.qml` exposes `settings`, `soundOn`,
  `setSetting()`, `resetProgress()`. `reduceMotion` / `textScale` are now
  computed: **desktop preference OR in-game setting** (`reduceMotionPref` /
  `baseTextScale` come from `Panel.qml`; `largeText` / `reduceMotion` from the
  grown-ups screen).

## Note on the detour

A mistyped `SequenceAnimation` (should be `SequentialAnimation`) in the first
draft of `Confetti.qml` made the whole QML tree fail to load with only
"Did not load any objects" for a diagnostic. Chasing it, some already-working
M3 wiring got reverted and then rebuilt. All restored; `dev/harness.qml` and
`dev/shoot.qml` load clean.

## Still open (post-M3)

- **Sound** — the toggle persists but no audio is wired yet (needs a working
  playback path from inside the shell; ship muted).
- **Number-pad input** for the higher levels (plan defers this).
- **Accessibility** — reduce-motion + larger-text are wired and honoured;
  a full keyboard focus-order / screen-reader pass is not done.
- **In-shell end-to-end test** on a scratch workspace — theme mapping and
  `FileView` persistence are only smoke-tested from M0, not re-run with the
  full game.

## Dev commands

```bash
node dev/tests/run.mjs
/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" -I . Game.qml ui/*.qml
QT_QPA_PLATFORM=offscreen /usr/bin/qml6 dev/shoot.qml
```
