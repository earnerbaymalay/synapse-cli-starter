# shellcheck shell=bash
# SynapseCli core: version, colour helpers, config, reserved names.
# Sourced by synapse-cli.sh and bin/synapse-fn. Never changes shell options.

: "${SYNAPSE_CLI_HOME:?SYNAPSE_CLI_HOME must be set}"
SYNAPSE_CLI_VERSION="$(cat "$SYNAPSE_CLI_HOME/VERSION" 2>/dev/null || echo 0.0.0)"

# Every command the pack defines. Custom functions may not shadow these
# without --force.
_SYN_BUILTINS=(
    synapse syn-fn syn-ask syn-qwen syn-llama syn-dolphin syn-hermes
    syn-warm syn-stop syn-flush syn-ps syn-mem syn-log syn-doctor
    syn-privacy syn-venv syn-clip syn-banner syn-widget syn-help
)

_syn_tty() { [[ -t 1 && -z "${NO_COLOR:-}" ]]; }

# _syn_paint <256-colour code> <text...>
_syn_paint() {
    local c="$1"
    shift
    if _syn_tty; then
        printf '\033[38;5;%sm%s\033[0m' "$c" "$*"
    else
        printf '%s' "$*"
    fi
}

_syn_err() { printf 'synapse-cli: %s\n' "$*" >&2; }

_syn_conf_file() { printf '%s/synapse/cli.conf' "${XDG_CONFIG_HOME:-$HOME/.config}"; }

# _syn_conf_get <key> [default]  - plain key=value parse; the file is never sourced.
_syn_conf_get() {
    local key="$1" def="${2:-}" f line val=""
    f="$(_syn_conf_file)"
    if [[ -r "$f" ]]; then
        while IFS= read -r line; do
            [[ "$line" == "$key="* ]] && val="${line#*=}"
        done <"$f"
    fi
    printf '%s' "${val:-$def}"
}

# _syn_resolve_model <alias|model>
_syn_resolve_model() {
    local n="$1" v
    case "$n" in
        qwen) v=qwen2.5-coder:latest ;;
        llama) v=llama3.2:latest ;;
        dolphin) v=dolphin-mistral:latest ;;
        hermes) v=nous-hermes2:latest ;;
        *) v="$(_syn_conf_get "alias.$n")" ;;
    esac
    printf '%s' "${v:-$n}"
}

# Valid ollama model reference (blocks JSON/shell metacharacters).
_syn_valid_model() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/:@-]{0,127}$ ]]; }

_syn_ollama_url() {
    local h="${OLLAMA_HOST:-127.0.0.1:11434}"
    [[ "$h" == http* ]] || h="http://$h"
    printf '%s' "$h"
}
