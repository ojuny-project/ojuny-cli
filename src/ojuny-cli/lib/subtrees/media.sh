media_play() {
    ojuny_require_command playerctl
    ojuny_exec playerctl play
}

media_pause() {
    ojuny_require_command playerctl
    ojuny_exec playerctl pause
}

media_play_pause() {
    ojuny_require_command playerctl
    ojuny_exec playerctl play-pause
}

media_next() {
    ojuny_require_command playerctl
    ojuny_exec playerctl next
}

media_previous() {
    ojuny_require_command playerctl
    ojuny_exec playerctl previous
}

media_stop() {
    ojuny_require_command playerctl
    ojuny_exec playerctl stop
}

media_status() {
    ojuny_require_command playerctl
    playerctl status
}

media_volume() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny media volume <value>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command playerctl
    ojuny_exec playerctl volume "$1"
}

media_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    play) media_play ;;
    pause) media_pause ;;
    play-pause | toggle) media_play_pause ;;
    next | skip) media_next ;;
    previous | rewind) media_previous ;;
    stop) media_stop ;;
    status) media_status ;;
    volume) media_volume "$@" ;;
    "")
        media_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny media <command>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
