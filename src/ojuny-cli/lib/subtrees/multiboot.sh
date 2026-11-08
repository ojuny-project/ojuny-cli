multiboot_manifest() {
    printf '/var/lib/ojuny/multiboot.json\n'
}

multiboot_require_root() {
    local verb="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "multiboot $verb requires root"
        ojuny_sudo_hint "multiboot $verb"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

multiboot_status() {
    local manifest
    manifest="$(multiboot_manifest)"
    if [ ! -r "$manifest" ]; then
        if ojuny_is_json; then
            ojuny_json_ok "multiboot.status" '{"enabled":false,"systems":[]}'
        else
            printf 'Multiboot helper is not enabled or has not scanned yet.\n'
        fi
        return 0
    fi
    ojuny_require_command jq
    if ojuny_is_json; then
        jq -c '{schema:1,command:"multiboot.status",ok:true,data:.,meta:{}}' "$manifest"
        return 0
    fi
    jq -r '
        "Helper: \(.helper_state)",
        "Secure Boot: \(if .secure_boot then "enabled" else "disabled" end)",
        "BitLocker: \(if .bitlocker then "detected" else "not detected" end)",
        "Boot partition: \(.boot_mount)",
        "Detected systems:",
        (if (.systems | length) == 0 then "  none" else (.systems[] | "  \(.kind)\t\(.label)\t\(.partition)") end)
    ' "$manifest"
}

multiboot_rescan() {
    ojuny_require_command systemctl
    multiboot_require_root rescan || return
    ojuny_exec systemctl start ojuny-multiboot.service
    multiboot_status
}

multiboot_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) multiboot_status ;;
    rescan) multiboot_rescan ;;
    "")
        multiboot_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny multiboot <status|rescan>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
