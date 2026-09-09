# Kids Math

A fun, progression-based math game for kids ages 5–12, as an
[Omarchy](https://omarchy.org) Quattro shell plugin. Add, subtract, multiply,
and divide across four "worlds", each with unlockable levels and star ratings.

> **Status: early development.** Milestone 0 (platform spike) is done — see
> [`MILESTONE-0.md`](MILESTONE-0.md). The game itself is being built next; the
> current `Panel.qml` is a placeholder. Full plan in [`PLAN.md`](PLAN.md).

## Install (once released)

```bash
omarchy plugin add https://github.com/elynch303/omarchy-math.git
omarchy plugin enable io.github.elynch303.kids-math
```

Then launch it from the **bar button**, from your app launcher, or bind a key:

```
omarchy-shell shell toggle io.github.elynch303.kids-math
```

### Suggested Hyprland window rule

```
windowrulev2 = float, class:^(org\.quickshell)$, title:^(Kids Math)$
windowrulev2 = center, class:^(org\.quickshell)$, title:^(Kids Math)$
windowrulev2 = size 900 700, class:^(org\.quickshell)$, title:^(Kids Math)$
```

## Development

```bash
qmllint -I "$OMARCHY_PATH/shell" *.qml
omarchy plugin validate .
bash dev/sync.sh          # copy into ~/.config/omarchy/plugins/ for the running shell
```

## License

MIT — see [`LICENSE`](LICENSE).
