ojuny_is_flake_ref() {
    case "$1" in
    *"#"*) return 0 ;;
    *:*) return 0 ;;
    ./* | ../* | /*) return 0 ;;
    esac
    return 1
}

ojuny_resolve_input() {
    local input="$1"
    local name flake attr

    if ojuny_is_flake_ref "$input"; then
        printf '%s\n' "$input"
        return 0
    fi

    case "$input" in
    */*)
        printf 'github:%s\n' "$input"
        return 0
        ;;
    esac

    while IFS=$'\t' read -r name flake attr; do
        [ -n "$name" ] || continue
        case "$name" in \#*) continue ;; esac
        if [ "$name" = "$input" ]; then
            if [ -n "$attr" ]; then
                printf '%s#%s\n' "$flake" "$attr"
            else
                printf '%s\n' "$flake"
            fi
            return 0
        fi
    done <"$OJUNY_LIB_DIR/official.tsv"

    printf 'nixpkgs#%s\n' "$input"
}

ojuny_split_nom_args() {
    OJUNY_NOM_INPUTS=()
    OJUNY_NOM_FLAGS=()
    local seen_flag=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --)
            shift
            OJUNY_NOM_FLAGS+=("$@")
            break
            ;;
        -*)
            seen_flag=1
            OJUNY_NOM_FLAGS+=("$1")
            shift
            ;;
        *)
            if [ "$seen_flag" -eq 1 ]; then
                OJUNY_NOM_FLAGS+=("$1")
            else
                OJUNY_NOM_INPUTS+=("$1")
            fi
            shift
            ;;
        esac
    done
}

build_cmd() {
    ojuny_require_command nom
    ojuny_split_nom_args "$@"

    if [ "${#OJUNY_NOM_INPUTS[@]}" -ne 1 ]; then
        ojuny_usage_error "usage: ojuny build <input> [-- flags]"
        return "$OJUNY_EXIT_USAGE"
    fi

    local input
    input="$(ojuny_resolve_input "${OJUNY_NOM_INPUTS[0]}")" || return
    ojuny_exec nom build "$input" "${OJUNY_NOM_FLAGS[@]}"
}

shell_cmd() {
    ojuny_require_command nom
    ojuny_split_nom_args "$@"

    if [ "${#OJUNY_NOM_INPUTS[@]}" -eq 0 ]; then
        ojuny_usage_error "usage: ojuny shell <input>... [-- flags]"
        return "$OJUNY_EXIT_USAGE"
    fi

    local input
    local -a resolved=()
    for input in "${OJUNY_NOM_INPUTS[@]}"; do
        resolved+=("$(ojuny_resolve_input "$input")")
    done
    ojuny_exec nom shell "${resolved[@]}" "${OJUNY_NOM_FLAGS[@]}"
}

develop_cmd() {
    ojuny_require_command nom
    ojuny_exec nom develop "$@"
}
