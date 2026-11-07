sound_list() {
    ojuny_require_command wpctl
    wpctl status
}

sound_current() {
    ojuny_require_command wpctl
    printf 'output: '
    wpctl get-volume @DEFAULT_AUDIO_SINK@
    printf 'input:  '
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@
}

sound_input() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny sound input <id>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command wpctl
    ojuny_exec wpctl set-default "$1"
}

sound_output() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny sound output <id>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command wpctl
    ojuny_exec wpctl set-default "$1"
}

sound_volume() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny sound volume <value>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command wpctl
    ojuny_exec wpctl set-volume @DEFAULT_AUDIO_SINK@ "$1"
}

sound_micvolume() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny sound micvolume <value>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command wpctl
    ojuny_exec wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$1"
}

sound_mute() {
    ojuny_require_command wpctl
    ojuny_exec wpctl set-mute @DEFAULT_AUDIO_SINK@ "${1:-toggle}"
}

sound_micmute() {
    ojuny_require_command wpctl
    ojuny_exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ "${1:-toggle}"
}

sound_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) sound_list "$@" ;;
    input) sound_input "$@" ;;
    output) sound_output "$@" ;;
    volume) sound_volume "$@" ;;
    micvolume) sound_micvolume "$@" ;;
    current) sound_current ;;
    mute) sound_mute "$@" ;;
    micmute) sound_micmute "$@" ;;
    "")
        sound_current
        ;;
    *)
        ojuny_usage_error "usage: ojuny sound <command>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
