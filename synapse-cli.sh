# shellcheck shell=bash
# SynapseCli — Synapse-branded opt-in bash starter pack for SynapseOS
# Provides local LLM shortcuts, Brain memory interaction, health diagnostics,
# and custom function management without any external branding.

if [[ -n "${_SYNAPSE_CLI_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_SYNAPSE_CLI_LOADED=1

SYNAPSE_CLI_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SYNAPSE_CLI_HOME

# Load core modules
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/core.sh"
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/ollama.sh"
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/mem.sh"
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/doctor.sh"
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/tools.sh"
# shellcheck disable=SC1091
source "$SYNAPSE_CLI_HOME/lib/fn.sh"

# Synapse binary wrapper: routes `synapse fn ...` to `syn-fn`, passes everything else to binary
synapse() {
    if [[ "${1:-}" == "fn" ]]; then
        shift
        syn-fn "$@"
    else
        command synapse "$@"
    fi
}

# Auto-source user-installed custom functions from ~/.config/synapse/functions/
if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/synapse/functions" ]]; then
    for _fn_file in "${XDG_CONFIG_HOME:-$HOME/.config}/synapse/functions"/*.sh; do
        if [[ -f "$_fn_file" ]]; then
            # shellcheck disable=SC1090
            source "$_fn_file" 2>/dev/null || true
        fi
    done
    unset _fn_file
fi

# Optional shell completions for syn-ask and syn-fn
_syn_ask_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local models
    models="qwen llama dolphin hermes $(curl -s --max-time 1 http://127.0.0.1:11434/api/tags 2>/dev/null | jq -r '.models[]?.name' 2>/dev/null | cut -d':' -f1 || true)"
    COMPREPLY=($(compgen -W "$models" -- "$cur"))
}
complete -F _syn_ask_complete syn-ask 2>/dev/null || true

_syn_fn_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local subs="add remove list edit run"
    COMPREPLY=($(compgen -W "$subs" -- "$cur"))
}
complete -F _syn_fn_complete syn-fn 2>/dev/null || true
