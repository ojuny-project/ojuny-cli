network_status() {
    ojuny_require_command nmcli
    nmcli general status
}

network_list() {
    ojuny_require_command nmcli
    nmcli device status
}

network_connect() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny network connect <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nmcli
    ojuny_exec nmcli connection up "$1"
}

network_disconnect() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny network disconnect <device>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nmcli
    ojuny_exec nmcli device disconnect "$1"
}

network_enable() {
    ojuny_require_command nmcli
    ojuny_exec nmcli networking on
}

network_disable() {
    ojuny_require_command nmcli
    ojuny_exec nmcli networking off
}

network_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) network_status ;;
    list) network_list ;;
    connect) network_connect "$@" ;;
    disconnect) network_disconnect "$@" ;;
    enable) network_enable ;;
    disable) network_disable ;;
    "")
        network_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny network <status|list|connect|disconnect|enable|disable>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
