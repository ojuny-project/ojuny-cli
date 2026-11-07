keybinds_open() {
    dux_keybinds_open
}

keybinds_list() {
    ojuny_require_command dms
    dms keybinds list
}

keybinds_show() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny keybinds show <provider>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command dms
    dms keybinds show "$1"
}

keybinds_subtree() {
    local command="${1:-open}"
    shift || true

    case "$command" in
    open) keybinds_open ;;
    list) keybinds_list ;;
    show) keybinds_show "$@" ;;
    *)
        ojuny_usage_error "usage: ojuny keybinds <open|list|show>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
