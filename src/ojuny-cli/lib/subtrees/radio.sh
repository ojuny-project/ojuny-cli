radio_list() {
    ojuny_require_command rfkill
    rfkill list
}

radio_wifi() {
    ojuny_require_command rfkill
    local value="${1:-}"
    case "$value" in
    on) ojuny_exec rfkill unblock wifi ;;
    off) ojuny_exec rfkill block wifi ;;
    *)
        ojuny_usage_error "usage: ojuny radio wifi [on|off]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

radio_bluetooth() {
    ojuny_require_command rfkill
    local value="${1:-}"
    case "$value" in
    on) ojuny_exec rfkill unblock bluetooth ;;
    off) ojuny_exec rfkill block bluetooth ;;
    *)
        ojuny_usage_error "usage: ojuny radio bluetooth [on|off]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

radio_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) radio_list ;;
    wifi) radio_wifi "$@" ;;
    bluetooth) radio_bluetooth "$@" ;;
    "")
        radio_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny radio <list|wifi|bluetooth>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
