# shellcheck shell=bash
# Tool helpers: venv, clipboard, banner, widget, help

syn-venv() {
    local target=""
    for candidate in .venv venv env "$HOME/.venvs/$(basename "$PWD")"; do
        if [[ -f "$candidate/bin/activate" ]]; then
            target="$candidate"
            break
        fi
    done

    if [[ -n "$target" ]]; then
        # shellcheck disable=SC1090
        source "$target/bin/activate"
        echo -e "\033[32m[✓]\033[0m Activated virtual environment: $target (Python $(python3 --version | cut -d' ' -f2))"
    else
        echo -e "\033[33m[!]\033[0m No virtualenv found in .venv, venv, or ~/.venvs/"
        echo "Create one with: python3 -m venv .venv"
        return 1
    fi
}

syn-clip() {
    if [[ ! -t 0 ]]; then
        if command -v wl-copy >/dev/null 2>&1; then
            wl-copy
        elif command -v xclip >/dev/null 2>&1; then
            xclip -selection clipboard
        else
            _syn_err "neither wl-copy nor xclip is available"
            return 1
        fi
        echo -e "\033[32m[✓]\033[0m Stdin copied to system clipboard"
    else
        if command -v wl-paste >/dev/null 2>&1; then
            wl-paste
        elif command -v xclip >/dev/null 2>&1; then
            xclip -selection clipboard -o
        else
            _syn_err "neither wl-paste nor xclip is available"
            return 1
        fi
    fi
}

syn-banner() {
    echo -e "\033[1;35m"
    cat << 'BANNER'
  ░████  ██  ██ ███ ██  ░███  █████   ░████  ██████        ░████░   ░████ 
 ░██░░░  ░██░██ ░███░█ ░██░██ ░██░██ ░██░░░  ░██░░░       ░██░░██░ ░██░░░ 
 ░░███░   ░███░ ░██░██ ░█████ ░████░ ░░███░  ░████        ░██  ██░ ░░███░ 
   ░░██░   ░██░ ░██░██ ░██░██ ░██░░░   ░░██░ ░██░░░       ░██░░██░   ░░██░
 ░████░    ░██░ ░██ ░█ ░██ ░█ ░██    ░████░  ░█████        ░████░  ░████░ 
BANNER
    echo -e "\033[0m"
    echo -e " \033[1;36mSynapseOS AI Cyberdeck CLI\033[0m · v${SYNAPSE_CLI_VERSION:-1.0.0} · Zero-Telemetry"
    echo
}

syn-widget() {
    local mem_count="0" model_status="idle"
    if command -v synapse >/dev/null 2>&1; then
        mem_count=$(synapse mem stats 2>/dev/null | awk '/Observations/ {print $2}' || echo "0")
    fi
    if command -v ollama >/dev/null 2>&1; then
        local resident
        resident=$(ollama ps 2>/dev/null | awk 'NR>1 {print $1}' | head -n1)
        if [[ -n "$resident" ]]; then
            model_status="$resident"
        fi
    fi
    echo -e "\033[1;34m[SYNAPSE]\033[0m \033[36mModel:\033[0m $model_status | \033[36mMemory:\033[0m $mem_count obs | \033[32mPrivacy:\033[0m DoT+MAC Random"
}

syn-help() {
    cat << 'HELP'
SynapseCli — Unified Agentic Bash Starter Pack for SynapseOS

Commands:
  syn-ask [-m model] [prompt]     Query local Ollama LLM (aliases: syn-qwen, syn-llama, syn-dolphin, syn-hermes)
  syn-warm [model]                Preload LLM into memory for instant inference
  syn-stop [model]                Unload LLM (or all resident models) from memory
  syn-flush                       Flush all resident LLMs from memory
  syn-ps                          Show loaded LLMs in memory
  syn-mem log|search|context      Fast agent memory interaction with Synapse Brain
  syn-log <note>                  Quickly record an observation into Synapse memory
  syn-doctor                      Comprehensive agent, binary, network, and security audit
  syn-privacy                     Display current MAC spoofing, DoT, and zero-telemetry posture
  syn-venv                        Auto-detect and activate virtualenv (.venv, venv)
  syn-clip                        Copy/paste from system clipboard (Wayland & X11)
  syn-fn add|remove|list|run      Manage user custom bash functions in ~/.config/synapse/functions/
  syn-banner                      Display the Cyberdeck ASCII banner
  syn-widget                      One-line status summary for prompt/status bars

Note:
  `synapse fn ...` routes to `syn-fn`, while all other `synapse ...` invocations pass
  directly to the Synapse core binary.
HELP
}
