clipboard_open() {
    dux_clipboard_open
}

clipboard_clear() {
    ojuny_require_command dms
    ojuny_exec dms clipboard clear
}

clipboard_echo() {
    ojuny_require_command dms
    dms clipboard paste
}

clipboard_copy() {
    ojuny_require_command dms
    if [ "$#" -gt 0 ]; then
        ojuny_exec dms clipboard copy "$1"
    else
        ojuny_exec dms clipboard copy
    fi
}

clipboard_history() {
    ojuny_require_command dms
    dms clipboard history
}

clipboard_search() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny clipboard search <text>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command dms
    dms clipboard search "$1"
}

clipboard_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    open) clipboard_open ;;
    clear) clipboard_clear ;;
    echo) clipboard_echo ;;
    copy) clipboard_copy "$@" ;;
    history) clipboard_history ;;
    search) clipboard_search "$@" ;;
    "")
        clipboard_open
        ;;
    *)
        ojuny_usage_error "usage: ojuny clipboard <open|clear|echo|copy|history|search>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
