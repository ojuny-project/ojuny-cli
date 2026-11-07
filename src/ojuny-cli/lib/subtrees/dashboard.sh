dashboard_toggle() {
    dux_call dash toggle
}

dashboard_open() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny dashboard open <tab>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_dashboard_open "$1"
}

dashboard_close() {
    dux_dashboard_close
}

dashboard_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    toggle) dashboard_toggle ;;
    open) dashboard_open "$@" ;;
    close) dashboard_close ;;
    "")
        dashboard_toggle
        ;;
    *)
        ojuny_usage_error "usage: ojuny dashboard <toggle|open|close>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
