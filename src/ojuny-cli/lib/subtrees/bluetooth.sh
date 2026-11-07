bluetooth_status() {
    ojuny_require_command bluetoothctl
    bluetoothctl show
}

bluetooth_list() {
    ojuny_require_command bluetoothctl
    bluetoothctl devices
}

bluetooth_scan() {
    ojuny_require_command bluetoothctl
    local value="${1:-on}"
    if [ "$value" = "on" ]; then
        ojuny_exec bluetoothctl --timeout 8 scan on
    else
        ojuny_exec bluetoothctl scan off
    fi
}

bluetooth_power() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth power [on|off]"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec bluetoothctl power "$1"
}

bluetooth_pair() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth pair <mac>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec bluetoothctl pair "$1"
}

bluetooth_connect() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth connect <mac>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec bluetoothctl connect "$1"
}

bluetooth_disconnect() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth disconnect <mac>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec bluetoothctl disconnect "$1"
}

bluetooth_trust() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth trust <mac>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec bluetoothctl trust "$1"
}

bluetooth_remove() {
    ojuny_require_command bluetoothctl
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny bluetooth remove <mac>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_confirm "Remove $1?" || return "$OJUNY_EXIT_OK"
    ojuny_exec bluetoothctl remove "$1"
}

bluetooth_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) bluetooth_status ;;
    list) bluetooth_list ;;
    scan) bluetooth_scan "$@" ;;
    power) bluetooth_power "$@" ;;
    pair) bluetooth_pair "$@" ;;
    connect) bluetooth_connect "$@" ;;
    disconnect) bluetooth_disconnect "$@" ;;
    trust) bluetooth_trust "$@" ;;
    remove) bluetooth_remove "$@" ;;
    "")
        bluetooth_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny bluetooth <command>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
