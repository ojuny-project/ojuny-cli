modem_default_id() {
    mmcli -L 2>/dev/null | grep -oE '/Modem/[0-9]+' | head -n 1 | cut -d/ -f3
}

modem_list() {
    ojuny_require_command mmcli
    mmcli -L
}

modem_status() {
    ojuny_require_command mmcli
    local id="${1:-}"
    [ -n "$id" ] || id="$(modem_default_id)"
    if [ -z "$id" ]; then
        ojuny_err "no modem found"
        return "$OJUNY_EXIT_VALIDATION"
    fi
    mmcli -m "$id"
}

modem_enable() {
    ojuny_require_command mmcli
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny modem enable <modem>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec mmcli -m "$1" --enable
}

modem_disable() {
    ojuny_require_command mmcli
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny modem disable <modem>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec mmcli -m "$1" --disable
}

modem_connect() {
    ojuny_require_command mmcli
    if [ "$#" -lt 2 ]; then
        ojuny_usage_error "usage: ojuny modem connect <modem> <apn>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec mmcli -m "$1" --simple-connect="apn=$2"
}

modem_disconnect() {
    ojuny_require_command mmcli
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny modem disconnect <modem>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_exec mmcli -m "$1" --simple-disconnect
}

modem_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) modem_status "$@" ;;
    list) modem_list ;;
    enable) modem_enable "$@" ;;
    disable) modem_disable "$@" ;;
    connect) modem_connect "$@" ;;
    disconnect) modem_disconnect "$@" ;;
    "")
        modem_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny modem <status|list|enable|disable|connect|disconnect>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
