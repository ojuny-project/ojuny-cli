doctor_subtree() {
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

    for command in mmsg dms nmcli bluetoothctl wpctl playerctl wg wg-quick nix git jq; do
        if command -v "$command" >/dev/null 2>&1; then
            printf 'ok: %s\n' "$command"
        else
            printf 'missing: %s\n' "$command"
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
