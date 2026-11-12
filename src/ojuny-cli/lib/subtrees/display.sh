display_list() {
    ojuny_require_session_command dms
    if ojuny_is_json; then
        dms randr --json
    else
        dms randr
    fi
}

display_current() {
    display_list
}

display_brightness_device() {
    ojuny_require_session_command dms
    dms brightness list 2>/dev/null | awk '/^backlight:/{ print $1; exit }'
}

display_brightness_get() {
    local device
    device="$(display_brightness_device)"
    if [ -z "$device" ]; then
        ojuny_err "no backlight device found"
        return "$OJUNY_EXIT_VALIDATION"
    fi
    dms brightness get "$device"
}

display_brightness_set() {
    local value="$1"
    local device
    device="$(display_brightness_device)"
    if [ -z "$device" ]; then
        ojuny_err "no backlight device found"
        return "$OJUNY_EXIT_VALIDATION"
    fi
    ojuny_exec dms brightness set "$device" "$value"
}

display_brightness_step() {
    local direction="$1"
    local current value
    current="$(display_brightness_get | grep -oE '[0-9]+' | tail -n 1)"
    if [ -z "$current" ]; then
        ojuny_err "cannot read current brightness"
        return "$OJUNY_EXIT_BACKEND"
    fi
    if [ "$direction" = "up" ]; then
        value=$((current + 5))
    else
        value=$((current - 5))
    fi
    [ "$value" -gt 100 ] && value=100
    [ "$value" -lt 0 ] && value=0
    display_brightness_set "$value"
}

display_brightness() {
    local action="${1:-get}"
    shift || true

    case "$action" in
    get) display_brightness_get ;;
    set)
        if [ "$#" -lt 1 ]; then
            ojuny_usage_error "usage: ojuny display brightness set <value>"
            return "$OJUNY_EXIT_USAGE"
        fi
        display_brightness_set "$1"
        ;;
    up) display_brightness_step up ;;
    down) display_brightness_step down ;;
    *)
        ojuny_usage_error "usage: ojuny display brightness [get|set <value>|up|down]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

display_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) display_list ;;
    current) display_current ;;
    brightness) display_brightness "$@" ;;
    "")
        display_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny display <list|current|brightness>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
