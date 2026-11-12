system_battery() {
    ojuny_require_command upower
    local device
    device="$(upower -e | grep -E '/battery_' | head -n 1)"
    if [ -z "$device" ]; then
        ojuny_err "no battery found"
        return "$OJUNY_EXIT_VALIDATION"
    fi
    upower -i "$device"
}

system_status() {
    local uptime_value load memory disk battery
    uptime_value="$(ojuny_probe uptime -p | sed 's/^up //')"
    if [ -z "$uptime_value" ]; then
        uptime_value="$(ojuny_probe uptime | sed 's/.*up //; s/, *[0-9]* users.*//')"
    fi
    load="$(cut -d' ' -f1-3 /proc/loadavg)"
    memory="$(free -h 2>/dev/null | awk '/^Mem:/{ print $3 " / " $2 }' || true)"
    disk="$(df -h / 2>/dev/null | awk 'NR==2 { print $3 " / " $2 " (" $5 ")" }' || true)"
    if command -v upower >/dev/null 2>&1; then
        battery="$(upower -e 2>/dev/null | grep -E '/battery_' | head -n 1 | xargs -r upower -i 2>/dev/null |
            awk -F: '/percentage|state/ { gsub(/^ +| +$/, "", $2); printf "%s%s", sep, $2; sep=", " }' || true)"
    fi
    [ -n "$battery" ] || battery="unknown"

    if ojuny_is_json; then
        jq -cn --arg uptime "$uptime_value" --arg load "$load" --arg memory "$memory" \
            --arg disk "$disk" --arg battery "$battery" \
            '{uptime:$uptime,load:$load,memory:$memory,disk:$disk,battery:$battery}'
        return 0
    fi

    printf 'uptime\t%s\nload\t%s\nmemory\t%s\ndisk\t%s\nbattery\t%s\n' \
        "$uptime_value" "$load" "$memory" "$disk" "$battery" | ojuny_kv_block
}

system_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) system_status ;;
    battery) system_battery ;;
    lock) system_lock ;;
    logout) system_logout ;;
    suspend) system_suspend ;;
    hibernate) system_hibernate ;;
    reboot) system_reboot ;;
    shutdown) system_shutdown ;;
    "")
        system_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny system <status|battery|lock|logout|suspend|hibernate|reboot|shutdown>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
