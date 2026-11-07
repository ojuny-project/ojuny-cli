service_systemctl() {
    if [ "$(id -u)" -eq 0 ] || ojuny_system_scope; then
        systemctl "$@"
    else
        systemctl --user "$@"
    fi
}

service_require_system_root() {
    local verb="$1"
    local name="$2"
    if ojuny_system_scope && [ "$(id -u)" -ne 0 ]; then
        ojuny_err "permission denied for system scope"
        ojuny_sudo_hint "service $verb $name"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

service_list() {
    ojuny_require_command systemctl
    service_systemctl list-units --type=service --no-pager
}

service_status() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service status <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_systemctl status --no-pager "$1"
}

service_start() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service start <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root start "$1" || return
    ojuny_exec service_systemctl start "$1"
}

service_stop() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service stop <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root stop "$1" || return
    ojuny_exec service_systemctl stop "$1"
}

service_restart() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service restart <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root restart "$1" || return
    ojuny_exec service_systemctl restart "$1"
}

service_reload() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service reload <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root reload "$1" || return
    ojuny_exec service_systemctl reload "$1"
}

service_enable() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service enable <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root enable "$1" || return
    ojuny_exec service_systemctl enable "$1"
}

service_disable() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny service disable <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command systemctl
    service_require_system_root disable "$1" || return
    ojuny_exec service_systemctl disable "$1"
}

service_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    list) service_list ;;
    status) service_status "$@" ;;
    start) service_start "$@" ;;
    stop) service_stop "$@" ;;
    restart) service_restart "$@" ;;
    reload) service_reload "$@" ;;
    enable) service_enable "$@" ;;
    disable) service_disable "$@" ;;
    "")
        service_list
        ;;
    *)
        ojuny_usage_error "usage: ojuny service <list|status|start|stop|restart|reload|enable|disable>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
