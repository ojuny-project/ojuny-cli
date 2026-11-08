bootorder_status() {
    ojuny_require_command efibootmgr
    if ojuny_is_json; then
        ojuny_json_ok "bootorder.status" "$(efibootmgr -v)"
    else
        efibootmgr -v
    fi
}

bootorder_require_root() {
    local verb="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "bootorder $verb requires root"
        ojuny_sudo_hint "bootorder $verb"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

bootorder_fix() {
    ojuny_require_command systemctl
    bootorder_require_root fix || return
    ojuny_exec systemctl start ojuny-bootorder.service
    bootorder_status
}

bootorder_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) bootorder_status ;;
    fix) bootorder_fix ;;
    "")
        bootorder_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny bootorder <status|fix>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
