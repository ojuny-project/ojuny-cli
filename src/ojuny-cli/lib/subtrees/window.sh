window_list() {
    mclientlist
}

window_kill() {
    mkillclient
}

window_focus() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny window focus <direction>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mfocusdir "$1"
}

window_move() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny window move <direction>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mmoveclient "$1"
}

window_exchange() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny window exchange <direction>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mexchangeclient "$1"
}

window_resize() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny window resize <direction>"
        return "$OJUNY_EXIT_USAGE"
    fi
    msmartresize "$1"
}

window_fullscreen() {
    mfullscreen
}

window_maximize() {
    mmaximize
}

window_float() {
    mfloat
}

window_float_all() {
    mfloatall
}

window_minimize() {
    mminimize
}

window_restore() {
    mrestore
}

window_pin() {
    mdispatch togglepin
}

window_overlay() {
    mdispatch toggleoverlay
}

window_detail() {
    mclientlist
}

window_tag_special() {
    mtagspecial
}

window_toggle_special() {
    mtogglespecial
}

window_group_leave() {
    mgroupleave
}

window_overview() {
    moverview
}

window_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) window_list ;;
    kill) window_kill ;;
    focus) window_focus "$@" ;;
    move) window_move "$@" ;;
    exchange) window_exchange "$@" ;;
    resize) window_resize "$@" ;;
    fullscreen) window_fullscreen ;;
    maximize) window_maximize ;;
    float) window_float ;;
    float-all) window_float_all ;;
    minimize) window_minimize ;;
    restore) window_restore ;;
    pin) window_pin ;;
    overlay) window_overlay ;;
    detail) window_detail ;;
    tag-special) window_tag_special ;;
    toggle-special) window_toggle_special ;;
    group-leave) window_group_leave ;;
    overview) window_overview ;;
    "")
        window_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny window <command>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
