# shellcheck shell=bash
# Custom function management for SynapseCli

_syn_fn_dir() {
    local d="${XDG_CONFIG_HOME:-$HOME/.config}/synapse/functions"
    mkdir -p "$d"
    echo "$d"
}

_syn_fn_manifest() {
    local m
    m="$(_syn_fn_dir)/manifest.tsv"
    if [[ ! -f "$m" ]]; then
        printf "NAME\tORIGIN\tDATE\tDESCRIPTION\n" > "$m"
    fi
    echo "$m"
}

syn-fn() {
    local sub="${1:-}"
    [[ $# -gt 0 ]] && shift
    case "$sub" in
        add)
            local name="${1:-}" file="${2:-}" desc="Custom user function" force=0
            if [[ -z "$name" ]]; then
                _syn_err "usage: syn-fn add <name> [file|-] [--desc <description>] [--force]"
                return 2
            fi
            # Validate name
            if [[ ! "$name" =~ ^[A-Za-z0-9_-]+$ ]]; then
                _syn_err "invalid function name: $name (use alphanumeric, dash, underscore)"
                return 2
            fi
            # Check builtins
            for b in "${_SYN_BUILTINS[@]}"; do
                if [[ "$name" == "$b" && $force -eq 0 ]]; then
                    _syn_err "cannot shadow built-in '$name' without --force"
                    return 1
                fi
            done
            local fdir m target
            fdir="$(_syn_fn_dir)"
            m="$(_syn_fn_manifest)"
            target="$fdir/${name}.sh"
            if [[ -n "$file" && "$file" != "-" ]]; then
                if [[ ! -f "$file" ]]; then
                    _syn_err "source file not found: $file"
                    return 1
                fi
                cp "$file" "$target"
            elif [[ "$file" == "-" || ! -t 0 ]]; then
                cat > "$target"
            else
                cat > "$target" << EOF
# Function: $name
$name() {
    echo "Executing $name: \$*"
}
EOF
            fi
            chmod +x "$target"
            # Update manifest
            local now
            now=$(date "+%Y-%m-%d")
            # Remove existing row if any
            grep -v -E "^${name}\t" "$m" > "${m}.tmp" 2>/dev/null || true
            mv "${m}.tmp" "$m"
            printf "%s\tuser\t%s\t%s\n" "$name" "$now" "$desc" >> "$m"
            echo -e "\033[32m[✓]\033[0m Added custom function: $name in $target"
            # Source into current shell if function is defined
            # shellcheck disable=SC1090
            source "$target" 2>/dev/null || true
            ;;
        remove|rm)
            local name="${1:-}"
            if [[ -z "$name" ]]; then
                _syn_err "usage: syn-fn remove <name>"
                return 2
            fi
            local fdir m target
            fdir="$(_syn_fn_dir)"
            m="$(_syn_fn_manifest)"
            target="$fdir/${name}.sh"
            if [[ -f "$target" ]]; then
                rm -f "$target"
                grep -v -E "^${name}\t" "$m" > "${m}.tmp" 2>/dev/null || true
                mv "${m}.tmp" "$m"
                unset -f "$name" 2>/dev/null || true
                echo -e "\033[32m[✓]\033[0m Removed custom function: $name"
            else
                _syn_err "function not found: $name"
                return 1
            fi
            ;;
        list|ls)
            local m
            m="$(_syn_fn_manifest)"
            echo -e "\033[1;36m=== Synapse Custom Functions ===\033[0m"
            if [[ -f "$m" ]]; then
                column -t -s $'\t' "$m"
            fi
            ;;
        edit)
            local name="${1:-}"
            if [[ -z "$name" ]]; then
                _syn_err "usage: syn-fn edit <name>"
                return 2
            fi
            local target
            target="$(_syn_fn_dir)/${name}.sh"
            if [[ -f "$target" ]]; then
                "${EDITOR:-nano}" "$target"
                # shellcheck disable=SC1090
                source "$target" 2>/dev/null || true
            else
                _syn_err "function not found: $name"
                return 1
            fi
            ;;
        run)
            local name="${1:-}"
            [[ $# -gt 0 ]] && shift
            if [[ -z "$name" ]]; then
                _syn_err "usage: syn-fn run <name> [args...]"
                return 2
            fi
            local target
            target="$(_syn_fn_dir)/${name}.sh"
            if [[ -f "$target" ]]; then
                # shellcheck disable=SC1090
                source "$target"
                if declare -F "$name" >/dev/null 2>&1; then
                    "$name" "$@"
                fi
            else
                _syn_err "function not found: $name"
                return 1
            fi
            ;;
        ""|-h|--help|help)
            cat << 'USAGE'
Usage: syn-fn <subcommand> [args...]

Subcommands:
  add <name> [file|-]    Install custom function into ~/.config/synapse/functions/
  remove <name>          Uninstall custom function
  list                   List installed custom functions & manifests
  edit <name>            Edit function in $EDITOR
  run <name> [args...]   Execute custom function
USAGE
            ;;
        *)
            _syn_err "unknown syn-fn subcommand: $sub"
            return 2
            ;;
    esac
}
