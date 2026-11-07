spotlight_toggle() {
    dux_spotlight_toggle
}

spotlight_open() {
    dux_spotlight_toggle
}

spotlight_close() {
    dux_spotlight_toggle
}

spotlight_query() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny spotlight query <text>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_spotlight_query "$1"
}

spotlight_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    toggle) spotlight_toggle ;;
    open) spotlight_open ;;
    close) spotlight_close ;;
    query) spotlight_query "$@" ;;
    "")
        spotlight_toggle
        ;;
    *)
        ojuny_usage_error "usage: ojuny spotlight <toggle|open|close|query>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
