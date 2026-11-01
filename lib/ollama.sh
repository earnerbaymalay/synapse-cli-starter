# shellcheck shell=bash
# Ollama helpers: syn-ask and the model lifecycle commands.

_syn_need_ollama() {
    command -v ollama >/dev/null 2>&1 || {
        _syn_err "ollama is not installed"
        return 127
    }
}

# True if the token looks like a model name or a known alias.
_syn_is_model_token() {
    case "$1" in
        qwen | llama | dolphin | hermes) return 0 ;;
    esac
    [[ -n "$(_syn_conf_get "alias.$1")" ]] && return 0
    [[ "$1" =~ ^[A-Za-z0-9._/-]+:[A-Za-z0-9._-]+$ ]]
}

syn-ask() {
    local model="" positional=() flags=() stdin_data
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                cat <<'USAGE'
Usage: syn-ask [-m model] [prompt...]      (prompt may also be piped on stdin)
       syn-ask <model|alias> [prompt...]   (aliases: qwen llama dolphin hermes)
Default model: default_model in ~/.config/synapse/cli.conf (qwen2.5-coder:latest)
USAGE
                return 0
                ;;
            -m | --model)
                [[ $# -ge 2 && -n "$2" ]] || {
                    _syn_err "-m/--model needs a value"
                    return 2
                }
                model="$2"
                shift 2
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done
    set -- "${positional[@]}"
    if [[ -z "$model" && $# -ge 1 ]] && _syn_is_model_token "$1" && { [[ $# -ge 2 ]] || [[ ! -t 0 ]] || [[ $# -eq 1 ]]; }; then
        model="$1"
        shift
    fi
    model="$(_syn_resolve_model "${model:-$(_syn_conf_get default_model qwen2.5-coder:latest)}")"
    _syn_valid_model "$model" || {
        _syn_err "invalid model name: $model"
        return 2
    }
    _syn_need_ollama || return $?
    # shellcheck disable=SC2206  # intentional word-splitting of a config value
    flags=($(_syn_conf_get ask_flags --think=false))
    local run=(ollama run "${flags[@]}" "$model")

    if [[ ! -t 0 ]]; then
        stdin_data="$(cat)"
        if [[ -n "$stdin_data" && $# -gt 0 ]]; then
            printf '%s\n\nTask: %s\n' "$stdin_data" "$*" | "${run[@]}"
        elif [[ -n "$stdin_data" ]]; then
            printf '%s\n' "$stdin_data" | "${run[@]}"
        elif [[ $# -gt 0 ]]; then
            "${run[@]}" "$*"
        else
            _syn_err "no prompt given and stdin was empty"
            return 2
        fi
    elif [[ $# -gt 0 ]]; then
        "${run[@]}" "$*"
    else
        "${run[@]}"
    fi
}

syn-qwen() { syn-ask -m qwen "$@"; }
syn-llama() { syn-ask -m llama "$@"; }
syn-dolphin() { syn-ask -m dolphin "$@"; }
syn-hermes() { syn-ask -m hermes "$@"; }

syn-ps() {
    _syn_need_ollama || return $?
    ollama ps
}

# syn-warm [model]  - preload a model into memory
syn-warm() {
    local model
    model="$(_syn_resolve_model "${1:-$(_syn_conf_get default_model qwen2.5-coder:latest)}")"
    _syn_valid_model "$model" || {
        _syn_err "invalid model name: $model"
        return 2
    }
    command -v curl >/dev/null 2>&1 || {
        _syn_err "curl is required"
        return 127
    }
    if curl -fsS --max-time 180 -X POST "$(_syn_ollama_url)/api/generate" \
        -d "{\"model\":\"$model\"}" >/dev/null; then
        echo "warmed $model"
    else
        _syn_err "could not warm $model (is ollama running?)"
        return 1
    fi
}

# syn-stop [model]  - unload one model, or all resident models
syn-stop() {
    _syn_need_ollama || return $?
    if [[ -n "${1:-}" ]]; then
        ollama stop "$(_syn_resolve_model "$1")"
        return $?
    fi
    local running m rc=0
    running="$(ollama ps | awk 'NR>1 {print $1}')"
    if [[ -z "$running" ]]; then
        echo "No resident models loaded."
        return 0
    fi
    for m in $running; do
        echo "Stopping $m"
        ollama stop "$m" || rc=1
    done
    return $rc
}

syn-flush() { syn-stop; }
