dux_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) dux_status ;;
    start) dux_start ;;
    stop) dux_stop ;;
    restart) dux_restart ;;
    ipc) dux_ipc "$@" ;;
    "")
        dux_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny dux <status|start|stop|restart|ipc>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
