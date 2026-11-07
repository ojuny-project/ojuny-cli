wifi_device() {
    nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2 == "wifi" { print $1; exit }'
}

wifi_status() {
    ojuny_require_command nmcli
    local device
    device="$(wifi_device)"
    printf 'radio: '
    nmcli radio wifi
    if [ -n "$device" ]; then
        printf 'device: %s\n' "$device"
        nmcli -t -f GENERAL.STATE device show "$device" 2>/dev/null
    fi
}

wifi_list() {
    ojuny_require_command nmcli
    nmcli device wifi list
}

wifi_scan() {
    ojuny_require_command nmcli
    ojuny_exec nmcli device wifi list --rescan yes
}

wifi_connect() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny wifi connect <ssid> [password]"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nmcli
    local ssid="$1"
    local password="${2:-}"
    if [ -n "$password" ]; then
        ojuny_exec nmcli device wifi connect "$ssid" password "$password"
    else
        ojuny_exec nmcli device wifi connect "$ssid"
    fi
}

wifi_disconnect() {
    ojuny_require_command nmcli
    local device
    device="$(wifi_device)"
    if [ -z "$device" ]; then
        ojuny_err "no Wi-Fi device found"
        return "$OJUNY_EXIT_VALIDATION"
    fi
    ojuny_exec nmcli device disconnect "$device"
}

wifi_enable() {
    ojuny_require_command nmcli
    ojuny_exec nmcli radio wifi on
}

wifi_disable() {
    ojuny_require_command nmcli
    ojuny_exec nmcli radio wifi off
}

wifi_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) wifi_status ;;
    list) wifi_list ;;
    scan) wifi_scan ;;
    connect) wifi_connect "$@" ;;
    disconnect) wifi_disconnect ;;
    enable) wifi_enable ;;
    disable) wifi_disable ;;
    "")
        wifi_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny wifi <status|list|scan|connect|disconnect|enable|disable>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
