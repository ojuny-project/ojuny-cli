notepad_open() {
    dux_call notepad open
}

notepad_toggle() {
    dux_notepad_toggle
}

notepad_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    open) notepad_open ;;
    toggle) notepad_toggle ;;
    "")
        notepad_open
        ;;
    *)
        ojuny_usage_error "usage: ojuny notepad <open|toggle>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
