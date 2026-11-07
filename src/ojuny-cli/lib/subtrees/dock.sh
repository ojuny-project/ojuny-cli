dock_status() {
    dux_call dock status
}

dock_toggle() {
    dux_call dock toggle
}

dock_autohide() {
    local value="${1:-toggle}"

    case "$value" in
    on | true)
        dux_call dock autoHide true
        ;;
    off | false)
        dux_call dock autoHide false
        ;;
    toggle)
        dux_call dock toggleAutoHide
        ;;
    *)
        ojuny_usage_error "usage: ojuny dock autohide [on|off|toggle]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

dock_subtree() {
    case "${1:-}" in
    status)
        shift
        dock_status "$@"
        ;;
    toggle)
        shift
        dock_toggle "$@"
        ;;
    autohide)
        shift
        dock_autohide "$@"
        ;;
    "")
        dock_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny dock <status|toggle|autohide>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
