# Milestone 4 — packaging

Everything needed to publish to <https://plugins.omarchy.org>.

## Added

- **`README.md`** — full rewrite: feature list, screenshots, install (bar /
  keybinding / app launcher), Hyprland window rules, uninstall, dev commands,
  roadmap.
- **`preview.png`** (1280×800) — marketplace card image, rendered headlessly by
  `dev/preview.qml`.
- **`screenshots/`** — home, round, result, grown-ups, for the GitHub page.
- **`extras/kids-math.desktop`** — optional app-launcher entry
  (`Exec=omarchy-shell shell toggle io.github.elynch303.kids-math`).
- **`dev/check.sh`** — one-command gate (logic tests + Qt6 qmllint + headless
  run that fails on any QML runtime error).
- `manifest.json` version → **0.4.0**.

## Verified

```
omarchy plugin validate .   → OK
bash dev/check.sh           → ALL GREEN  (109,329 assertions; qmllint clean; no QML errors)
no symlinks in the tree
```

Plus the M3 in-shell run: loads clean in the real Quickshell, progress read +
write both work.

## Publishing checklist (from publish.html)

- [x] Public GitHub repo — `github.com/elynch303/omarchy-math`
- [x] Valid `manifest.json` at root (schemaVersion, id, name, version, author,
      description, kinds, entryPoints)
- [x] `id` namespaced, not `omarchy.*` — `io.github.elynch303.kids-math`
- [x] README + LICENSE (MIT)
- [x] No symlinks
- [x] Safe install/removal — inherent to the plugin model; the `.desktop` step
      is manual and documented
- [x] `preview.png`
- [x] `omarchy plugin validate` passes
- [ ] **Push to GitHub**
- [ ] **Submit the marketplace issue form** (repo link · category: Games ·
      tags: kids, education, math, game) — this is a public submission under the
      author's GitHub account, so the author does it, not the tooling.

## Suggested marketplace submission

> **Repository:** https://github.com/elynch303/omarchy-math
> **Category:** Games
> **Tags:** kids, education, math, arithmetic, game
> **Description:** A fun math game for kids 5–12 — add, subtract, multiply and
> divide across four worlds with unlockable levels and stars. Keyboard and
> mouse, theme-aware, progress saved locally, with a grown-ups area for
> settings and progress.
