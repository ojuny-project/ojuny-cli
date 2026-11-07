secureboot_require_root() {
    local verb="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "secureboot $verb requires root"
        ojuny_sudo_hint "secureboot $verb"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

secureboot_status() {
    ojuny_require_command sbctl
    sbctl status
}

secureboot_list() {
    ojuny_require_command sbctl
    sbctl list-files
}

secureboot_verify() {
    ojuny_require_command sbctl
    sbctl verify
}

secureboot_sign() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny secureboot sign <file>"
        return "$OJUNY_EXIT_USAGE"
    fi
    secureboot_require_root sign || return
    ojuny_exec sbctl sign "$1"
}

secureboot_sign_all() {
    secureboot_require_root sign-all || return
    ojuny_exec sbctl sign-all
}

secureboot_bundle() {
    secureboot_require_root bundle || return
    ojuny_exec sbctl bundle
}

secureboot_enroll() {
    secureboot_require_root enroll || return
    ojuny_exec sbctl enroll-keys
}

secureboot_create_keys() {
    secureboot_require_root create-keys || return
    ojuny_exec sbctl create-keys
}

secureboot_reset() {
    secureboot_require_root reset || return
    ojuny_confirm "Reset Secure Boot keys?" || return "$OJUNY_EXIT_OK"
    ojuny_exec sbctl reset
}

secureboot_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) secureboot_status ;;
    list) secureboot_list ;;
    verify) secureboot_verify ;;
    sign) secureboot_sign "$@" ;;
    sign-all) secureboot_sign_all ;;
    bundle) secureboot_bundle ;;
    enroll) secureboot_enroll ;;
    create-keys) secureboot_create_keys ;;
    reset) secureboot_reset ;;
    "")
        secureboot_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny secureboot <status|list|verify|sign|sign-all|bundle|enroll|create-keys|reset>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
