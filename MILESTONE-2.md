# Milestone 2 — all four worlds + Home screen

Verified headlessly (`dev/shoot.qml`, offscreen). Screenshots: `/tmp/km-1-home.png`
… `/tmp/km-5-round-div.png`.

## What's in

- **Subtraction, Multiplication, Division** generators added to
  `logic/problems.js`, each 7 levels following the `PLAN.md` ladder:
  - sub: take-away to 5/10/20 → 2-digit − 1-digit → no-borrow → borrowing →
    three terms. Never goes negative at any step.
  - mul: 1s/2s → 2s,5s,10s → 3s,4s → 6s–9s → tables to 12 → 2-digit × 1-digit →
    three factors.
  - div: always built quotient × divisor, so every answer is whole. By 2 →
    2,5,10 → 3,4 → 6–9 → facts to 12 → 2-digit ÷ 1-digit → 3-digit ÷ 1-digit.
- Wrong-answer distractors now world-aware (the "ran the other operation" trap
  differs per world).
- `logic/progression.js` — level blurbs for all four worlds.
- **Tests: 109,329 assertions, all green** — arithmetic correctness, whole
  non-negative answers, valid 4-choice sets, no-borrow/borrow and carry
  checks, even division, per-world level shapes, determinism.

- **`ui/HomeScreen.qml`** — the landing screen: title, total-star count, four
  world tiles (coloured symbol, name, star tally, progress bar).
- **`ui/Mascot.qml`** — a no-assets mascot with `idle / happy / oops / think`
  moods (arc-drawn smile/frown via Canvas). Shown on the round and result
  screens, reacting to answers and star count.
- `Game.qml` now starts on `home`; `home → levels → round → result` navigation,
  with the level screen's back arrow returning to `home`.

## Not yet (M3 polish)

- Grown-ups screen (settings + reset, behind a gate)
- Number-pad input, re-queue-on-wrong, sound
- Confetti / streak animations, larger animated mascot
- Accessibility pass (reduce-motion is wired; large-text is wired; colourblind
  check + focus order still to verify)
- In-shell end-to-end test on a scratch workspace

## Dev commands

```bash
node dev/tests/run.mjs
/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" -I . Game.qml ui/*.qml
QT_QPA_PLATFORM=offscreen /usr/bin/qml6 dev/shoot.qml
```
