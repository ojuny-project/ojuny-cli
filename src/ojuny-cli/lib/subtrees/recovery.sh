recovery_manifest() {
    printf '/var/lib/ojuny/recovery.json\n'
}

recovery_require_root() {
    local verb="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "recovery $verb requires root"
        ojuny_sudo_hint "recovery $verb"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

recovery_status() {
    local manifest
    manifest="$(recovery_manifest)"
    if [ ! -r "$manifest" ]; then
        if ojuny_is_json; then
            ojuny_json_ok "recovery.status" '{"enabled":false}'
        else
            printf 'Recovery UKI is not enabled or has not been built yet.\n'
        fi
        return 0
    fi
    ojuny_require_command jq
    if ojuny_is_json; then
        jq -c '{schema:1,command:"recovery.status",ok:true,data:.,meta:{}}' "$manifest"
        return 0
    fi
    jq -r '
        "Recovery UKI: \(.uki)",
        "Signed: \(.signed)",
        "Generation: \(.toplevel)",
        "Last build: \(.generated_at)"
    ' "$manifest"
}

recovery_rebuild() {
    ojuny_require_command systemctl
    recovery_require_root rebuild || return
    ojuny_exec systemctl start ojuny-recovery.service
    recovery_status
}

recovery_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) recovery_status ;;
    rebuild) recovery_rebuild ;;
    "")
        recovery_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny recovery <status|rebuild>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
