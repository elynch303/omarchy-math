# Kids Math — Omarchy Plugin Plan

A simple, fun, progression-based math game for kids ages 5–12, packaged as an
Omarchy Quattro shell plugin and published to
<https://plugins.omarchy.org/publish.html>.

---

## 1. Goals

- **Fun first.** Bright, friendly, low-text, big touch targets. A 5-year-old
  should be able to play without reading much.
- **Real learning progression.** Four operations (addition, subtraction,
  multiplication, division), each a "world" with unlockable levels and star
  ratings.
- **Gentle.** Encouraging feedback, no harsh timers, wrong answers teach rather
  than punish.
- **Native to Omarchy.** Matches the desktop theme, launchable the way the user
  expects (bar button, keybinding, and app launcher), and can run fullscreen or
  floating.
- **Publishable.** Passes `omarchy plugin validate`, has a public GitHub repo,
  README, license, and a preview image.

---

## 2. Key constraint: what an Omarchy Quattro plugin actually is

Everything on <https://plugins.omarchy.org> is a **QML surface that runs inside
the single long-running `omarchy-shell` (Quickshell) process** — not a
standalone binary. The marketplace's automated check validates a `manifest.json`
with `kinds` + `entryPoints` pointing at QML files. So to be publishable there,
the game must be built as a shell plugin, not a separate app.

Plugins run **unsandboxed** with the user's permissions and share the shell
process. Third-party plugins get **capability-scoped facades** rather than full
host objects (bar widgets get detached state; other kinds see only their own
service). This shapes what APIs we can rely on — see §7.

### How "works like any other app" maps onto that

| User expectation        | How we deliver it as a plugin |
|-------------------------|-------------------------------|
| Launch from a bar button | `bar-widget` kind — a small "🔢 Math" button on the bar that opens the game |
| Launch from a keybinding | `omarchy-shell shell toggle io.github.elynch303.kids-math` bound to a hotkey (documented in README) |
| Launch from the app launcher | Ship an optional `kids-math.desktop` file whose `Exec=` calls the `omarchy-shell shell toggle …` command; README shows the one-line copy into `~/.local/share/applications/` |
| Fullscreen / Floating / tiled | `panel` kind — a `FloatingWindow`. It's a real Hyprland toplevel, so the WM handles float / tile / fullscreen. Ship a suggested `windowrule` (float + center + size) in the README |
| "Feels like a window" | It *is* a window — nothing extra needed |

The plugin declares **two kinds** — `bar-widget` + `panel` (+ `keepLoaded: true`) —
both backed by one shared `Game.qml`. Confirmed working in Milestone 0; the
built-in `omarchy.menu` uses the same `bar-widget` + surface pairing.

---

## 3. Plugin architecture

### Repo / plugin layout

```
omarchy-math/              # repo: git@github.com:elynch303/omarchy-math.git
├── manifest.json          # schemaVersion 1, id, kinds, entryPoints, keepLoaded
├── BarWidget.qml          # bar button -> IPC toggle (done, M0)
├── Panel.qml              # FloatingWindow wrapper -> loads Game.qml
├── Game.qml               # the actual game
├── dev/sync.sh            # copy repo -> ~/.config/omarchy/plugins/<id>/ (done, M0)
├── ui/
│   ├── HomeScreen.qml     # world select (Add / Sub / Mult / Div)
│   ├── LevelSelect.qml    # level map for a world, stars shown
│   ├── RoundScreen.qml    # the question loop
│   ├── ResultScreen.qml   # stars earned, "play again" / "next level"
│   ├── GrownUpsScreen.qml # settings + progress, behind a simple gate
│   ├── AnswerButton.qml   # big reusable answer tile
│   └── Character.qml      # mascot + reactions (idle / cheer / oops)
├── logic/
│   ├── Problems.js        # problem generator per operation + level
│   ├── Progression.js     # levels, unlock rules, star thresholds
│   └── Store.js           # load/save progress JSON
├── assets/                # svg mascot, star, icons, (optional) sounds
├── preview.png            # marketplace preview image
├── README.md
├── LICENSE                # MIT (confirm)
└── PLAN.md                # this file
```

### manifest.json (draft)

```json
{
  "schemaVersion": 1,
  "id": "io.github.elynch303.kids-math",
  "name": "Kids Math",
  "version": "0.1.0",
  "author": "elynch303",
  "license": "MIT",
  "description": "A fun math game for kids 5–12 — add, subtract, multiply, divide with levels and stars.",
  "kinds": ["bar-widget", "panel", "overlay"],
  "entryPoints": {
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml",
    "overlay": "Overlay.qml"
  },
  "barWidget": {
    "displayName": "Kids Math",
    "description": "Launch the kids math game",
    "category": "Games",
    "allowMultiple": false,
    "defaultSection": "right"
  }
}
```

---

## 4. Game design

### Structure

```
Home  ─►  World (operation)  ─►  Level map  ─►  Round (10 questions)  ─►  Results (0–3 stars)
```

- **Worlds:** Addition, Subtraction, Multiplication, Division. Each shown as a
  colourful tile with a mascot and a progress ring.
- **Levels:** 6–8 per world, laid out as a little "path" of stepping stones.
  A level unlocks when the previous one has **≥ 2 stars**. First level of each
  world is always unlocked.
- **Round:** 10 questions at the level's difficulty. A streak meter fills with
  consecutive correct answers and adds bonus sparkle.
- **Stars:** 3 stars = 10/10, 2 stars = 8–9, 1 star = 6–7, else "try again"
  (still keeps best result).
- **Rewards (v1 light):** stars accumulate into a per-world total and a grand
  total shown on Home. Cosmetic unlocks (mascot hats, background colours) are a
  stretch goal, not v1.

### Difficulty ladder (per world)

| Level | Addition | Subtraction | Multiplication | Division |
|------:|----------|-------------|----------------|----------|
| 1 | sums to 5 | within 5 | ×1, ×2 | ÷1, ÷2 |
| 2 | sums to 10 | within 10 | ×2, ×5, ×10 | ÷2, ÷5, ÷10 |
| 3 | sums to 20 | within 20 | ×3, ×4 | ÷3, ÷4 |
| 4 | 2-digit + 1-digit | 2-digit − 1-digit | ×6, ×7, ×8, ×9 | ÷6…÷9 |
| 5 | 2-digit + 2-digit (no carry) | 2-digit − 2-digit (no borrow) | tables to 12 | facts to 12 |
| 6 | 2-digit + 2-digit (carry) | 2-digit − 2-digit (borrow) | 2-digit × 1-digit | 2-digit ÷ 1-digit (no remainder) |
| 7+ | 3 addends / missing addend | missing number | missing factor | with remainder |

Division always uses whole-number answers in v1 (except the explicit
"remainder" levels).

### Age guidance (shown to grown-ups, not a gate)

- **5–6:** Addition & Subtraction, levels 1–3
- **7–8:** finish Add/Sub, Multiplication levels 1–3
- **9–10:** Multiplication & Division to 12
- **11–12:** levels 6–7, mixed / missing-number

### Answer input

- **Primary:** 4 big multiple-choice tiles (one correct + 3 plausible
  distractors — near misses, common mistakes like off-by-one or swapped
  operation).
- **Levels 5+:** optional on-screen number pad (toggle in grown-ups settings),
  for kids ready to produce answers rather than recognise them.

### Feedback

- Correct → mascot cheers, tile turns green, chime, streak +1, short confetti.
- Wrong → mascot says "oops, let's see" (no scary red X), correct tile glows,
  brief "X + Y = Z" reminder, streak resets, question is re-queued once later in
  the round. No score penalty beyond the missed star.
- End of round → star animation, encouraging line ("You're getting faster at
  6× !"), buttons: **Play again**, **Next level** (if unlocked), **Home**.

### No punishing timer

v1 has **no countdown**. A relaxed "how quick were you?" stat may be shown on the
results screen for older kids. A true timed "challenge mode" is deferred to a
later version.

### Grown-ups area

Reached via a "Grown-ups" button that asks a quick gate ("What is 7 × 8?" typed
answer, or press-and-hold 3s). Contains:

- Per-child-ish progress view (v1 = single profile; multi-profile is a stretch
  goal): stars per world, levels cleared, accuracy trend.
- Toggles: sound on/off, number-pad input on/off, reduce-motion, larger text.
- **Reset progress** (with confirm).

---

## 5. Visual & interaction design

- **Theme-aware.** Pull base colours/spacing/radius from the shell theme tokens
  (`Color.*`, `Style.*`) so it matches Omarchy, then layer a playful skin:
  rounded cards, thick friendly borders, a simple SVG mascot, big rounded
  buttons. Confirm which theme tokens are exposed to third-party `panel`/
  `overlay` plugins; fall back to a self-contained palette if not.
- **Layout.** Single centred column, max ~640px content width even in fullscreen,
  everything else breathing room. Works at panel size (~480×640) and fullscreen.
- **Type.** Very large numerals (question ~64px, answers ~40px). Minimal words.
- **Accessibility.** Colourblind-safe palette (never rely on red/green alone —
  also use ✓ / ↻ icons and position), reduce-motion option, larger-text option,
  keyboard playable (arrows + Enter to pick a tile, Esc to leave), all targets
  ≥ 64px.
- **Animation.** QML `Behavior`/`NumberAnimation` for transitions; a small
  particle burst for correct answers. Keep it cheap — this runs inside the shell
  process.
- **Sound (optional, gated).** Short chimes for correct/wrong/star. Needs an
  audio-playback path available to the plugin — confirm during build; ship muted
  by default and behind the sound toggle if unavailable.

---

## 6. Progression & content logic (framework-free JS)

- `Problems.js` — `generate(operation, level)` → `{ prompt, answer, choices }`.
  Pure functions, easy to unit-test with plain node.
- `Progression.js` — the level table above, `isUnlocked(world, level, progress)`,
  `starsFor(correct, total)`.
- Distractor strategy: mix of ±1/±2, right digits wrong order, result of the
  wrong operation, and a random in-range number; dedupe; shuffle.

---

## 7. Persistence

Progress is a small JSON blob:

```json
{
  "version": 1,
  "settings": { "sound": true, "numpad": false, "reduceMotion": false, "largeText": false },
  "worlds": {
    "add": { "levels": { "1": { "bestStars": 3, "bestScore": 10, "plays": 4 } } }
  },
  "totals": { "stars": 12 }
}
```

- **Preferred:** Quickshell `FileView` with a `JsonAdapter` (or `PersistentProperties`)
  writing to the plugin's own state dir.
- **Need to confirm:** whether third-party `panel`/`overlay` plugins are allowed
  `Quickshell.Io` file access and what the correct writable path is
  (`~/.local/state/omarchy/plugins/<id>/` or similar).
- **Fallback:** a tiny helper process (`Quickshell.Io.Process`) that reads/writes
  `~/.config/omarchy/kids-math/progress.json`, or in-memory only for the first
  prototype.

This is the single biggest technical unknown — resolve it in Milestone 0.

---

## 8. Build milestones

**M0 — Spike (validate the platform assumptions)**
- `omarchy plugin clone omarchy.weather --edit` to get a real working template.
- Stand up a stub `io.github.elynch303.kids-math` with a bar widget that toggles
  an overlay showing "Hello". Confirm: multi-kind manifest validates, bar button
  works, keybinding toggle works, `.desktop` launcher works, theme tokens
  available, **file persistence works**.
- Output: a de-risked skeleton + notes updating §2/§5/§7 of this plan.

**M1 — Core game loop (one world)**
- `Problems.js` + `Progression.js` for Addition, with node unit tests.
- `RoundScreen` + `AnswerButton` + `ResultScreen`, playable start-to-stars.
- Keyboard + mouse input.

**M2 — Full structure**
- Home (world select), LevelSelect (level path + stars), all four operations.
- Persistence wired in; unlock rules enforced.
- Mascot component with idle/cheer/oops states.

**M3 — Kid polish**
- Animations, confetti, streak meter, encouraging copy.
- Grown-ups screen: gate, progress view, settings toggles, reset.
- Accessibility pass (reduce-motion, large-text, colourblind-safe, focus order).
- Optional sound behind toggle.

**M4 — Package & publish**
- `README.md` (what it is, screenshots, install, keybinding, app-launcher
  `.desktop`, uninstall), `LICENSE`, `preview.png`.
- `omarchy plugin validate` clean; `qmllint` clean.
- Manual test matrix (§9).
- Push to public repo `github.com/elynch303/omarchy-math` (exists, empty).
  SSH key isn't configured on this machine — push over HTTPS using the `gh`
  token, or set `git remote` to `https://github.com/elynch303/omarchy-math.git`.
- Submit via the marketplace GitHub issue form (repo link, category = Games,
  tags: kids, education, math, game).

---

## 9. Test matrix (manual, pre-publish)

- Discovery: appears in `omarchy plugin list --json`, enable/disable works.
- Bar widget: shows, click toggles game, survives shell restart.
- Panel window: opens, Esc closes, window close button closes cleanly.
- Keybinding toggle and `.desktop` launcher both open it. ✅ (M0)
- Play a full round in each world; unlock gating correct; stars saved.
- Kill & restart shell → progress persists.
- Settings toggles take effect and persist.
- Reset progress works and confirms.
- Remove plugin (`omarchy plugin remove`) leaves no stray processes/files
  (document where progress.json lives so users can delete it).
- `qmllint -I "$OMARCHY_PATH/shell"` on every QML file.

---

## 10. Publishing checklist (from publish.html)

- [ ] Public GitHub repo
- [ ] Valid `manifest.json` at repo root (`schemaVersion`, `id`, `name`,
      `version`, `author`, `description`, `kinds`, `entryPoints`)
- [ ] `id` is namespaced and not `omarchy.*` → `io.github.elynch303.kids-math`
- [ ] README + LICENSE
- [ ] No symlinks in the plugin folder
- [ ] Safe install/removal (no install hooks, no sudo) — inherent to the plugin
      model; the optional `.desktop` step is manual and documented
- [ ] `preview.png`
- [ ] `omarchy plugin clone <repo>` + `omarchy plugin validate` pass locally
- [ ] Submit the marketplace issue form with repo link, category, tags

---

## 11. Open questions / risks

1. ~~**Persistence API**~~ — **RESOLVED (M0).** `Quickshell.Io` `Process` +
   `FileView` (`setText`/`atomicWrites`) → `~/.local/state/omarchy/plugins/<id>/`.
   Survives shell restart.
2. ~~**Multi-kind ergonomics**~~ — **RESOLVED (M0).** `["bar-widget","panel"]`
   works. No separate `overlay` kind needed: the `panel`'s `FloatingWindow` is a
   real Hyprland window — the WM does fullscreen/floating; ship a suggested
   windowrule. Requires `visible: root.opened` binding + `keepLoaded: true`.
3. ~~**Theme token access**~~ — **RESOLVED (M0).** `qs.Commons` / `qs.Ui` render
   in a third-party panel.
4. **Audio playback** availability — ship muted / optional.
5. **Quattro is alpha (`4.0.0.alpha`) and moving** — pin to the `quattro`
   branch; expect `schemaVersion`/API churn and be ready to bump `version`.
6. ~~`elynch303` GitHub handle~~ — **resolved.** Handle `elynch303`, repo
   `github.com/elynch303/omarchy-math` (public, currently empty). Plugin `id`
   locked to `io.github.elynch303.kids-math` (the `id` need not match the repo
   name; kept "kids-math" for marketplace clarity and to avoid an `omarchy-`
   prefix in a third-party id).
7. **Single profile in v1** — multi-child profiles are a common ask; noted as a
   stretch goal so the storage schema leaves room (`worlds` could become
   `profiles.<name>.worlds` later).
8. **Content review** — double-check generated problems for each level
   (especially division whole-number constraint and "no carry/borrow" levels).

---

## 12. Suggested v1 scope cut (if we need to ship sooner)

Must-have: all four worlds, 5 levels each, multiple-choice, stars + unlocking,
persistence, bar button + keybinding, README/LICENSE/preview, validation pass.

Defer: number-pad input, sound, cosmetic rewards, multi-profile, challenge/timed
mode, levels 6–7, animated mascot (start with 3 static poses).
