toggle_list() {
    local night idle dnd
    ojuny_require_session_command dms
    night="$(ojuny_probe dux_call night status | head -n 1)"
    idle="$(ojuny_probe dux_call inhibit status | head -n 1)"
    dnd="$(ojuny_probe dux_call notifications getDoNotDisturb | head -n 1)"

    if ojuny_is_json; then
        jq -cn --arg night "$night" --arg idle "$idle" --arg dnd "$dnd" \
            '{night:$night,idle:$idle,dnd:$dnd}'
        return 0
    fi

    printf 'night\t%s\nidle\t%s\ndnd\t%s\n' "$night" "$idle" "$dnd" | ojuny_kv_block
}

toggle_night() {
    local value="${1:-toggle}"
    case "$value" in
    on | true) dux_call night enable ;;
    off | false) dux_call night disable ;;
    toggle) dux_call night toggle ;;
    *)
        ojuny_usage_error "usage: ojuny toggle night [on|off|toggle]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

toggle_idle() {
    local value="${1:-toggle}"
    case "$value" in
    on | true) dux_call inhibit enable ;;
    off | false) dux_call inhibit disable ;;
    toggle) dux_call inhibit toggle ;;
    *)
        ojuny_usage_error "usage: ojuny toggle idle [on|off|toggle]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

toggle_dnd() {
    local value="${1:-toggle}"
    case "$value" in
    on | true) dux_call notifications enableDoNotDisturbIndefinitely ;;
    off | false) dux_call notifications disableDoNotDisturb ;;
    toggle) dux_call notifications toggleDoNotDisturb ;;
    *)
        ojuny_usage_error "usage: ojuny toggle dnd [on|off|toggle]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

toggle_lockscreen() {
    system_lock
}

toggle_screensaver() {
    system_lock
}

toggle_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) toggle_list ;;
    night) toggle_night "$@" ;;
    idle) toggle_idle "$@" ;;
    dnd) toggle_dnd "$@" ;;
    lockscreen) toggle_lockscreen ;;
    screensaver) toggle_screensaver ;;
    "")
        toggle_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny toggle <list|night|idle|dnd|lockscreen|screensaver>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
