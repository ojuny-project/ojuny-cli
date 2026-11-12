capture_menu() {
    if command -v ojuny-screenshot-menu >/dev/null 2>&1; then
        ojuny_exec ojuny-screenshot-menu
        return
    fi
    capture_toolbar
}

capture_region() {
    ojuny_require_session_command dms
    ojuny_exec dms screenshot region
}

capture_full() {
    ojuny_require_session_command dms
    ojuny_exec dms screenshot full
}

capture_window() {
    ojuny_require_session_command dms
    ojuny_exec dms screenshot window
}

capture_scroll() {
    if command -v ojuny-capture-scroll >/dev/null 2>&1; then
        ojuny_exec ojuny-capture-scroll
        return
    fi
    ojuny_require_session_command dms
    ojuny_exec dms screenshot scroll
}

capture_text() {
    ojuny_require_command ojuny-capture-text
    ojuny_exec ojuny-capture-text
}

capture_qr() {
    ojuny_require_command ojuny-capture-qr
    ojuny_exec ojuny-capture-qr
}

capture_edit() {
    ojuny_require_command ojuny-screenshot-edit
    ojuny_exec ojuny-screenshot-edit "$@"
}

capture_toolbar() {
    dux_capture_toolbar
}

capture_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    menu) capture_menu ;;
    region) capture_region ;;
    full) capture_full ;;
    window) capture_window ;;
    scroll) capture_scroll ;;
    text) capture_text ;;
    qr) capture_qr ;;
    edit) capture_edit "$@" ;;
    toolbar) capture_toolbar ;;
    "")
        capture_menu
        ;;
    *)
        ojuny_usage_error "usage: ojuny capture <menu|region|full|window|scroll|text|qr|edit|toolbar>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
