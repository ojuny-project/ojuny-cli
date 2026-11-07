island_status() {
    dux_call island status
}

island_open() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny island open <activity>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_island_open "$1"
}

island_show() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny island show <activity>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_island_show "$1"
}

island_cycle() {
    dux_island_cycle
}

island_move() {
    if [ "$#" -lt 2 ]; then
        ojuny_usage_error "usage: ojuny island move <x> <y>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_island_move "$@"
}

island_center() {
    if [ "$#" -lt 2 ]; then
        ojuny_usage_error "usage: ojuny island center <x> <y>"
        return "$OJUNY_EXIT_USAGE"
    fi
    dux_island_center "$@"
}

island_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) island_status ;;
    open) island_open "$@" ;;
    show) island_show "$@" ;;
    cycle) island_cycle ;;
    move) island_move "$@" ;;
    center) island_center "$@" ;;
    "")
        island_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny island <status|open|show|cycle|move|center>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
