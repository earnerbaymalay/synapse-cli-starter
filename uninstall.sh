#!/usr/bin/env bash
# Uninstaller for SynapseCli Starter Pack
set -euo pipefail

TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/synapse-cli"
BIN_DIR="${HOME}/.local/bin"
BASHRC="${HOME}/.bashrc"
MANAGED_START="# >>> synapse-cli starter pack >>>"
MANAGED_END="# <<< synapse-cli starter pack <<<"

echo "=== Uninstalling SynapseCli Starter Pack ==="

if [[ -f "$BASHRC" && $(grep -c "$MANAGED_START" "$BASHRC") -gt 0 ]]; then
    sed -i "/$MANAGED_START/,/$MANAGED_END/d" "$BASHRC"
    echo "[✓] Removed managed block from $BASHRC"
fi

rm -rf "$TARGET_DIR"
rm -f "$BIN_DIR/synapse-fn"

echo -e "\033[32m[✓]\033[0m SynapseCli completely removed."
