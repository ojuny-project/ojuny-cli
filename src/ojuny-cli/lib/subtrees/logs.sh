logs_run() {
    local unit=""
    local system_scope=0
    local -a args=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --follow | -f)
            args+=(-f)
            shift
            ;;
        --since)
            [ "$#" -ge 2 ] || {
                ojuny_usage_error "--since requires a value"
                return "$OJUNY_EXIT_USAGE"
            }
            args+=(--since "$2")
            shift 2
            ;;
        --lines | -n)
            [ "$#" -ge 2 ] || {
                ojuny_usage_error "--lines requires a value"
                return "$OJUNY_EXIT_USAGE"
            }
            args+=(-n "$2")
            shift 2
            ;;
        --system)
            system_scope=1
            shift
            ;;
        -*)
            ojuny_usage_error "unknown logs option: $1"
            return "$OJUNY_EXIT_USAGE"
            ;;
        *)
            unit="$1"
            shift
            ;;
        esac
    done

    ojuny_require_command journalctl

    if [ -n "$unit" ]; then
        args+=(-u "$unit")
    fi

    if [ "${#args[@]}" -eq 0 ]; then
        args=(-n 50)
    fi

    if [ "$(id -u)" -eq 0 ] || [ "$system_scope" -eq 1 ]; then
        journalctl "${args[@]}"
    else
        journalctl --user "${args[@]}"
    fi
}

logs_subtree() {
    logs_run "$@"
}
