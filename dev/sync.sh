#!/usr/bin/env bash
# Dev helper: copy the plugin source into the Omarchy user plugin directory
# so the running shell picks it up (the inotify watcher auto-reloads on change).
# Symlinks are rejected by the plugin loader, so this is a real copy.
set -euo pipefail

PLUGIN_ID="io.github.elynch303.kids-math"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$PLUGIN_ID"

mkdir -p "$DEST_DIR"
rsync -a --delete \
  --exclude '.git/' \
  --exclude 'dev/' \
  --exclude 'PLAN.md' \
  --exclude '*.md' \
  "$SRC_DIR/" "$DEST_DIR/"

echo "Synced $SRC_DIR -> $DEST_DIR"
