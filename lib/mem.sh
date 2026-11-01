# shellcheck shell=bash
# Memory shortcuts over `synapse mem` (the Synapse Brain memory, no vault).

_syn_need_synapse() {
    command -v synapse >/dev/null 2>&1 || {
        _syn_err "the synapse binary was not found on PATH"
        return 127
    }
}

# syn-log <note...>   record a quick observation
syn-log() {
    if [[ $# -eq 0 ]]; then
        _syn_err "usage: syn-log <note>"
        return 2
    fi
    _syn_need_synapse || return $?
    local note="$*" title
    title="${note:0:72}"
    command synapse mem observe "$title" -n "$note" -k note --topic log \
        --model "${SYNAPSE_MODEL:-synapse-cli}"
}

# syn-mem log|search|context [args...]
syn-mem() {
    local sub="${1:-}"
    [[ $# -gt 0 ]] && shift
    case "$sub" in
        log) syn-log "$@" ;;
        search | find)
            _syn_need_synapse || return $?
            command synapse mem search "$@"
            ;;
        context | ctx)
            _syn_need_synapse || return $?
            command synapse mem context "$@"
            ;;
        "" | -h | --help | help)
            echo "Usage: syn-mem {log <note> | search [query...] | context}"
            ;;
        *)
            _syn_err "unknown syn-mem command: $sub"
            return 2
            ;;
    esac
}
