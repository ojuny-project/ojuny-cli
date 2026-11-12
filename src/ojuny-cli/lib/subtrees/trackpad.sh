trackpad_state_file() {
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/ojuny/trackpad"
}

trackpad_state() {
    local file
    file="$(trackpad_state_file)"
    if [ -r "$file" ]; then
        cat "$file"
    else
        printf 'on\n'
    fi
}

trackpad_save_state() {
    local file
    file="$(trackpad_state_file)"
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$1" >"$file"
}

trackpad_devices() {
    mmsg_get all-devices | jq -r '[.devices[] | select(.types | index("trackpad")) | .name] | .[]'
}

trackpad_status() {
    local state devices
    state="$(trackpad_state)"
    devices="$(trackpad_devices)"

    if ojuny_is_json; then
        jq -cn --arg state "$state" --arg devices "$devices" \
            '{state:$state,devices:($devices | split("\n") | map(select(length > 0)))}'
        return 0
    fi

    printf 'state\t%s\n' "$state"
    [ -n "$devices" ] && printf 'devices\t%s\n' "$(printf '%s' "$devices" | paste -sd, -)"
}

trackpad_toggle() {
    local current next
    ojuny_require_session_command mmsg
    current="$(trackpad_state)"
    if [ "$current" = "on" ]; then
        next="off"
    else
        next="on"
    fi
    ojuny_exec_quiet mmsg dispatch toggle_trackpad_enable || return
    trackpad_save_state "$next"
}

trackpad_set() {
    local wanted="$1"
    local current
    ojuny_require_session_command mmsg
    current="$(trackpad_state)"
    if [ "$current" = "$wanted" ]; then
        return 0
    fi
    ojuny_exec_quiet mmsg dispatch toggle_trackpad_enable || return
    trackpad_save_state "$wanted"
}

trackpad_on() {
    trackpad_set on
}

trackpad_off() {
    trackpad_set off
}

trackpad_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) trackpad_status ;;
    on) trackpad_on ;;
    off) trackpad_off ;;
    toggle) trackpad_toggle ;;
    "")
        trackpad_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny trackpad <status|on|off|toggle>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
