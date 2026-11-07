vpn_status() {
    ojuny_require_command nmcli
    local active
    active="$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null |
        awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1 "\t" $2 "\t" $3 }')"
    if [ -z "$active" ]; then
        printf 'no active VPN\n'
        return 0
    fi
    printf '%s\n' "$active"
}

vpn_list() {
    ojuny_require_command nmcli
    nmcli -t -f NAME,TYPE connection show 2>/dev/null |
        awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1 "\t" $2 }'
}

vpn_up() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny vpn up <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nmcli
    ojuny_exec nmcli connection up "$1"
}

vpn_down() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny vpn down <name>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nmcli
    ojuny_exec nmcli connection down "$1"
}

vpn_watch_dir() {
    local override="${1:-}"

    if [ -n "$override" ]; then
        printf '%s\n' "$override"
        return 0
    fi

    if [ -n "${OJUNY_WIREGUARD_DIR:-}" ]; then
        printf '%s\n' "$OJUNY_WIREGUARD_DIR"
        return 0
    fi

    local flake host configured
    if flake="$(ojuny_flake_root 2>/dev/null)" && host="$(ojuny_host_name 2>/dev/null)"; then
        configured="$(nix eval --raw "$flake#nixosConfigurations.$host.config.ojuny.vpn.wireguard.directory" 2>/dev/null || true)"
        if [ -n "$configured" ] && [ "$configured" != "null" ]; then
            printf '%s\n' "$configured"
            return 0
        fi
    fi

    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/ojuny/wireguard"
}

vpn_import() {
    local dir=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --dir)
            [ "$#" -ge 2 ] || {
                ojuny_usage_error "--dir requires a path"
                return "$OJUNY_EXIT_USAGE"
            }
            dir="$2"
            shift 2
            ;;
        *)
            break
            ;;
        esac
    done

    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny vpn import <file> [--dir <path>]"
        return "$OJUNY_EXIT_USAGE"
    fi

    local source="$1"
    case "$source" in
    *.conf) ;;
    *)
        ojuny_err "not a WireGuard profile: $source"
        return "$OJUNY_EXIT_VALIDATION"
        ;;
    esac

    if [ ! -f "$source" ]; then
        ojuny_err "file not found: $source"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    local target_dir target
    target_dir="$(vpn_watch_dir "$dir")"
    target="$target_dir/$(basename "$source")"

    if [ -e "$target" ]; then
        ojuny_confirm "Overwrite $target?" || return "$OJUNY_EXIT_OK"
    fi

    mkdir -p "$target_dir"
    if ojuny_is_dry_run; then
        ojuny_exec install -m600 "$source" "$target"
        return 0
    fi

    install -m600 "$source" "$target"

    if ojuny_is_json; then
        jq -cn --arg source "$source" --arg target "$target" \
            '{changed:true,target:$target,source:$source}'
        return 0
    fi

    printf 'imported: %s\n' "$target"
    printf 'NetworkManager will pick the profile up from the watch directory.\n'
}

vpn_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) vpn_status ;;
    list) vpn_list ;;
    up) vpn_up "$@" ;;
    down) vpn_down "$@" ;;
    import) vpn_import "$@" ;;
    "")
        vpn_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny vpn <status|list|up|down|import>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
