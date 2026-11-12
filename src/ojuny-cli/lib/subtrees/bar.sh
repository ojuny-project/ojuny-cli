bar_toggle() {
    dux_bar_toggle
}

bar_show() {
    dux_bar_reveal
}

bar_hide() {
    dux_bar_hide
}

bar_subtree() {
    case "${1:-}" in
    toggle)
        shift
        bar_toggle "$@"
        ;;
    show)
        shift
        bar_show "$@"
        ;;
    hide)
        shift
        bar_hide "$@"
        ;;
    "")
        bar_toggle
        ;;
    *)
        ojuny_usage_error "usage: ojuny bar <toggle|show|hide>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
