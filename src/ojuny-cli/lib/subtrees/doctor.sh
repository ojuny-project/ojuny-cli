doctor_check() {
    local status=0
    local flake=""
    local host=""
    local command
    local config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
    local dux_config="$config_root/dms"
    local legacy_config="$config_root/DankMaterialShell"

    if flake="$(ojuny_flake_root)"; then
        printf 'flake: %s\n' "$flake"
    else
        printf 'flake: unknown\n'
        status=1
    fi

    if [ -n "$flake" ]; then
        if host="$(ojuny_host_name)"; then
            printf 'host: %s\n' "$host"
        else
            printf 'host: unknown\n'
            status=1
        fi
    else
        printf 'host: unknown\n'
    fi

    if [ -d "$dux_config" ]; then
        printf 'ok: config %s\n' "$dux_config"
    else
        printf 'missing: config %s\n' "$dux_config"
        status=1
    fi

    if [ -d "$legacy_config" ]; then
        printf 'legacy: config %s exists; Dux Modular Shell now uses %s\n' "$legacy_config" "$dux_config"
    fi

    printf 'session: %s\n' "$(ojuny_session_summary)"

    for command in dms mmsg nmcli mmcli bluetoothctl wpctl playerctl rfkill \
        udisksctl systemctl loginctl journalctl sbctl upower wtype ydotool \
        nix nixos-rebuild nix-settings-gui git jq; do
        if command -v "$command" >/dev/null 2>&1; then
            printf 'ok: %s\n' "$command"
        else
            case "$command" in
            dms | mmsg) printf 'missing: %s (no graphical session)\n' "$command" ;;
            *) printf 'missing: %s\n' "$command" ;;
            esac
            status=1
        fi
    done

    if [ -n "$flake" ] && [ -n "$host" ]; then
        ojuny_print_patch_state || status=1
    else
        printf '  patches: unknown\n'
    fi

    return "$status"
}

doctor_crashes() {
    ojuny_require_command coredumpctl
    coredumpctl list
}

doctor_boot() {
    ojuny_require_command systemd-analyze
    systemd-analyze
    printf '\n'
    systemd-analyze blame | head -n 15
}

doctor_subtree() {
    local command="${1:-check}"
    shift || true

    case "$command" in
    check) doctor_check ;;
    crashes) doctor_crashes ;;
    boot) doctor_boot ;;
    *)
        ojuny_usage_error "usage: ojuny doctor [check|crashes|boot]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
