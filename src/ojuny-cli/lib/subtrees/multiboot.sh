multiboot_manifest() {
    printf '%s\n' "${OJUNY_MULTIBOOT_MANIFEST:-/var/lib/ojuny/multiboot.json}"
}

multiboot_require_root() {
    local verb="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "multiboot $verb requires root"
        ojuny_sudo_hint "multiboot $verb"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}

multiboot_rescan_hint() {
    command -v efibootmgr >/dev/null 2>&1 || return 1
    ojuny_probe efibootmgr -v | grep -q "Windows Boot Manager"
}

multiboot_unit_exists() {
    ojuny_probe systemctl list-unit-files ojuny-multiboot.service 2>/dev/null | grep -q '^ojuny-multiboot\.service'
}

multiboot_status() {
    local manifest systems hint=""
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
    if ! jq -e . "$manifest" >/dev/null 2>&1; then
        ojuny_err "multiboot manifest is not valid JSON: $manifest"
        printf '  hint: sudo ojuny multiboot rescan\n' >&2
        return "$OJUNY_EXIT_VALIDATION"
    fi

    systems="$(jq -r '.systems | length' "$manifest")"
    if [ "$systems" -eq 0 ]; then
        if multiboot_unit_exists; then
            multiboot_rescan_hint && hint="run sudo ojuny multiboot rescan"
        else
            hint="enable ojuny.multiboot and rebuild to detect other systems"
        fi
    fi

    if ojuny_is_json; then
        jq -c --arg hint "$hint" '{schema:1,command:"multiboot.status",ok:true,data:.,meta:{hint:$hint}}' "$manifest"
        return 0
    fi
    jq -r '
        "Helper: \(.helper_state // "unknown")",
        "Generated: \(.generated_at // "unknown")",
        "Secure Boot: \(if .secure_boot then "enabled" else "disabled" end)",
        "BitLocker: \(if .bitlocker then "detected" else "not detected" end)",
        "Boot partition: \(.boot_mount // "unknown")",
        "Detected systems:",
        (if (.systems | length) == 0 then "  none" else (.systems[] | "  \(.kind)\t\(.label)\t\(.partition)") end)
    ' "$manifest"
    [ -z "$hint" ] || printf '  hint: %s\n' "$hint"
}

multiboot_rescan() {
    ojuny_require_command systemctl
    multiboot_require_root rescan || return
    if ! multiboot_unit_exists; then
        ojuny_err "multiboot helper is not enabled"
        printf '  hint: set ojuny.multiboot.enable = true and rebuild\n' >&2
        return "$OJUNY_EXIT_BACKEND"
    fi
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
