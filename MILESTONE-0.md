# Milestone 0 — platform spike results

Ran on a live **Omarchy 4.0.0.alpha (Quattro)** machine, shell running
(`quickshell -n -p /usr/share/omarchy/shell`). Goal: de-risk every platform
assumption in `PLAN.md` before building the real game.

## Verdict: green. Build proceeds as planned.

| # | Assumption | Result |
|---|------------|--------|
| 1 | Multi-kind `["bar-widget","panel"]` manifest validates | ✅ `omarchy plugin validate` passes; `omarchy plugin list` shows both kinds |
| 2 | `id` `io.github.elynch303.kids-math` is accepted | ✅ passes the id regex; not in the reserved `omarchy.*` namespace |
| 3 | Bar button can launch the game | ✅ `bar.run("omarchy-shell shell toggle <id>")` — the exact pattern the built-in `omarchy.menu` uses |
| 4 | `omarchy plugin enable` wires it into the bar | ✅ adds one entry to `bar.layout.right`; the panel half is picked up by the same enabled state |
| 5 | A third-party `panel` renders as a real window | ✅ `FloatingWindow` shows as an `org.quickshell` Hyprland toplevel — Hyprland tiles/floats/fullscreens it like any app |
| 6 | Shell lifecycle contract reaches a third-party panel | ✅ host injects `shell` + `manifest`; `open(payloadJson)` / `close()` / `opened` all fire as documented in `shell.qml` |
| 7 | Theme tokens reach a third-party surface | ✅ `qs.Commons` `Color.background/foreground/accent`, `Style.font.*`, `Style.space()`, and `qs.Ui` `Button` all render themed |
| 8 | **Progress can be persisted** (the big unknown) | ✅ `Quickshell.Io` `Process` (`mkdir -p`) + `FileView` `setText` with `atomicWrites` writes `~/.local/state/omarchy/plugins/<id>/…json`; survives toggles and a full shell restart |
| 9 | App-launcher entry | ✅ a `.desktop` with `Exec=omarchy-shell shell toggle <id>` opens the game |

## Gotchas found (feed into the real build)

- **`visible: root.opened` binding, not imperative `window.visible = …`.** With
  the imperative approach the window rendered the first time but not on repeat
  toggles. Binding `FloatingWindow.visible` to `opened` + `keepLoaded: true` in
  the manifest made it reliable.
- **`keepLoaded: true`** avoids a destroy/recreate race on every toggle. The
  game is lightweight enough to stay resident.
- **The inotify auto-reloader can wedge** under a burst of file writes (the dev
  `rsync` loop). Symptom: panel stops loading, no console output. Fix: the shell
  self-heals on restart (it's supervised) — or just sync less often. Not a
  shipping concern.
- **`FileView` load/increment race.** The first `open()` can beat the file read;
  guard writes behind a "state ready" flag and flush a queued open once the read
  lands, or the on-disk value overwrites the increment.
- **`console.log` from a plugin** shows in `journalctl --user` as `DEBUG qml:` —
  fine for dev.
- The window opens on whatever workspace is active when summoned. For a kids
  game, ship a suggested Hyprland windowrule (float + center + size) in the
  README, keyed on `class:^(org\.quickshell)$ title:^(Kids Math)$`.

## Artifacts from the spike

- `manifest.json` — real manifest (kinds, entryPoints, barWidget block, keepLoaded)
- `BarWidget.qml` — final shape (thin button → IPC toggle)
- `Panel.qml` — **throwaway spike UI**, replaced in Milestone 1 by the game
- `dev/sync.sh` — copies the repo into `~/.config/omarchy/plugins/<id>/` for the
  running shell to pick up (symlinks are rejected by the loader)

## Test commands (for reference)

```bash
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" Panel.qml BarWidget.qml
bash dev/sync.sh
omarchy plugin enable io.github.elynch303.kids-math
omarchy-shell shell toggle io.github.elynch303.kids-math
omarchy plugin list --json | jq '.[] | select(.id=="io.github.elynch303.kids-math")'
```
