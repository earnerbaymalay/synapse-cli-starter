#!/usr/bin/env bash
# Test harness for SynapseCli
set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

echo "=== Running SynapseCli Test Suite ==="

export HOME="$TEST_DIR"
export XDG_CONFIG_HOME="$TEST_DIR/.config"
export XDG_DATA_HOME="$TEST_DIR/.local/share"
touch "$HOME/.bashrc"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Test installation
echo -n "Test 1: Non-interactive install... "
"$SCRIPT_DIR/install.sh" --yes >/dev/null
if [[ -f "$HOME/.local/share/synapse-cli/synapse-cli.sh" && -f "$HOME/.local/bin/synapse-fn" ]]; then
    echo "OK"
else
    echo "FAIL"; exit 1
fi

# 2. Test sourcing
echo -n "Test 2: Source pack in bash subshell... "
bash -c "source '$HOME/.local/share/synapse-cli/synapse-cli.sh' && declare -F syn-ask && declare -F syn-fn" >/dev/null
echo "OK"

# 3. Test syn-fn custom function add/list/run/remove
echo -n "Test 3: Custom function lifecycle (syn-fn)... "
bash -c "
source '$HOME/.local/share/synapse-cli/synapse-cli.sh'
syn-fn add test_cmd - << 'EOF'
test_cmd() { echo \"output_val_\$1\"; }
EOF
out=\$(syn-fn run test_cmd hello)
[[ \"\$out\" == \"output_val_hello\" ]] || exit 1
syn-fn list | grep -q 'test_cmd' || exit 1
syn-fn remove test_cmd || exit 1
" >/dev/null
echo "OK"

# 4. Test uninstallation
echo -n "Test 4: Clean uninstall... "
"$SCRIPT_DIR/uninstall.sh" >/dev/null
if [[ ! -d "$HOME/.local/share/synapse-cli" && ! -f "$HOME/.local/bin/synapse-fn" ]]; then
    if ! grep -q "synapse-cli starter pack" "$HOME/.bashrc"; then
        echo "OK"
    else
        echo "FAIL (managed block remained in .bashrc)"; exit 1
    fi
else
    echo "FAIL (files remained)"; exit 1
fi

echo -e "\033[32m=== All SynapseCli Tests Passed ===\033[0m"
