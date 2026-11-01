#!/usr/bin/env bash
# Installer for SynapseCli Starter Pack (Opt-in / Idempotent)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/synapse-cli"
BIN_DIR="${HOME}/.local/bin"
BASHRC="${HOME}/.bashrc"
AUTO_YES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) AUTO_YES=1; shift ;;
        -u|--uninstall)
            exec "$SCRIPT_DIR/uninstall.sh" "$@"
            ;;
        *) shift ;;
    esac
done

if [[ $AUTO_YES -eq 0 && -t 0 ]]; then
    echo "=== SynapseCli Starter Pack Setup ==="
    echo "This will install the SynapseCli bash pack into ~/.local/share/synapse-cli"
    echo "and add an opt-in source block to your ~/.bashrc."
    read -r -p "Proceed with installation? [y/N]: " ans
    if [[ ! "$ans" =~ ^[yY](es)?$ ]]; then
        echo "Installation aborted."
        exit 0
    fi
fi

mkdir -p "$TARGET_DIR" "$BIN_DIR"
cp -r "$SCRIPT_DIR/lib" "$SCRIPT_DIR/synapse-cli.sh" "$SCRIPT_DIR/VERSION" "$TARGET_DIR/"
install -m 755 "$SCRIPT_DIR/bin/synapse-fn" "$BIN_DIR/synapse-fn"

# Managed block in .bashrc
MANAGED_START="# >>> synapse-cli starter pack >>>"
MANAGED_END="# <<< synapse-cli starter pack <<<"

if [[ -f "$BASHRC" ]]; then
    # Remove existing managed block if present
    if grep -q "$MANAGED_START" "$BASHRC"; then
        sed -i "/$MANAGED_START/,/$MANAGED_END/d" "$BASHRC"
    fi
    cat >> "$BASHRC" << EOF

$MANAGED_START
if [ -f "$TARGET_DIR/synapse-cli.sh" ]; then
    source "$TARGET_DIR/synapse-cli.sh"
fi
$MANAGED_END
EOF
fi

echo -e "\033[32m[✓]\033[0m SynapseCli installed successfully."
echo -e "[✓] Sourced in: $BASHRC"
echo -e "[✓] Binary available: $BIN_DIR/synapse-fn"
echo -e "To activate now, run: source $TARGET_DIR/synapse-cli.sh"
