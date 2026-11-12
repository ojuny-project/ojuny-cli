support_de_wm() {
    local desktop wm session_type version
    desktop="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-unknown}}}"
    wm=""

    local file comm
    for file in /proc/[0-9]*/comm; do
        { read -r comm <"$file"; } 2>/dev/null || continue
        case "$comm" in
        mango | hyprland | sway | niri | gnome-shell | plasmashell | weston | wayfire | labwc)
            wm="$comm"
            break
            ;;
        esac
    done

    session_type="unknown"
    if [ -n "${XDG_SESSION_ID:-}" ] && command -v loginctl >/dev/null 2>&1; then
        session_type="$(loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true)"
        [ -n "$session_type" ] || session_type="unknown"
    fi

    version=""
    case "$wm" in
    mango)
        version="$(mmsg get version 2>/dev/null | jq -r '.version // empty' 2>/dev/null || true)"
        ;;
    esac
    if [ -z "$version" ] && command -v dms >/dev/null 2>&1; then
        version="$(dms version 2>/dev/null | head -n 1)"
    fi

    printf '%s' "${desktop}"
    [ "$session_type" != "unknown" ] && printf ' (%s)' "$session_type"
    [ -n "$wm" ] && printf ' · %s' "$wm"
    [ -n "$version" ] && printf ' · %s' "$version"
    printf '\n'
}

support_backend_line() {
    local command="$1"
    if command -v "$command" >/dev/null 2>&1; then
        printf '  %-20s present\n' "$command"
        return 0
    fi
    case "$command" in
    dms | mmsg) printf '  %-20s missing (no graphical session)\n' "$command" ;;
    *) printf '  %-20s missing\n' "$command" ;;
    esac
}

support_render() {
    local flake host branch revision dirty

    printf 'ojuny support bundle\n'
    printf '  generated: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  ojuny:     %s\n' "${OJUNY_VERSION:-unknown}"
    printf '  host:      %s\n' "$(uname -n)"
    printf '\n'

    ojuny_heading 'Flake'
    flake="$(ojuny_flake_root 2>/dev/null)" || flake="unknown"
    host="$(ojuny_host_name 2>/dev/null)" || host="unknown"
    branch="unknown"
    revision="unknown"
    dirty="unknown"
    if [ "$flake" != "unknown" ]; then
        branch="$(ojuny_git_branch "$flake")"
        revision="$(ojuny_git_revision "$flake")"
        dirty="$(ojuny_git_dirty "$flake")"
    fi
    printf '  flake:     %s\n' "$flake"
    printf '  host:      %s\n' "$host"
    printf '  git:       %s @ %s (%s)\n' "$branch" "$revision" "$dirty"
    printf '\n'

    ojuny_heading 'System'
    printf '  DE/WM:     %s\n' "$(support_de_wm)"
    printf '  kernel:    %s\n' "$(uname -r)"
    printf '  nixos:     %s\n' "$(nixos-version 2>/dev/null || printf 'unknown')"
    printf '  uptime:    %s\n' "$(uptime -p 2>/dev/null || uptime 2>/dev/null | sed 's/.*up //; s/, *[0-9]* users.*//')"
    printf '  memory:    %s\n' "$(free -h 2>/dev/null | awk '/^Mem:/{ print $3 " / " $2 }')"
    printf '  disk:      %s\n' "$(df -h / | awk 'NR==2 { print $3 " / " $2 " (" $5 ")" }')"
    printf '  cpu:       %s\n' "$(awk -F': ' '/model name/ { print $2; exit }' /proc/cpuinfo)"
    printf '\n'

    ojuny_heading 'Session'
    printf '  desktop:   %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
    printf '  session:   %s\n' "${XDG_SESSION_DESKTOP:-unknown}"
    printf '  summary:   %s\n' "$(ojuny_session_summary)"
    if [ -n "${XDG_SESSION_ID:-}" ] && command -v loginctl >/dev/null 2>&1; then
        loginctl show-session "$XDG_SESSION_ID" -p Type -p Active -p Remote 2>/dev/null |
            sed 's/^/  /'
    fi

    if command -v nmcli >/dev/null 2>&1; then
        printf '\n'
        ojuny_heading 'Network'
        nmcli general status 2>/dev/null | sed 's/^/  /'
        printf '\n'
        nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | sed 's/^/  /'
    fi

    if command -v bluetoothctl >/dev/null 2>&1; then
        printf '\n'
        ojuny_heading 'Bluetooth'
        bluetoothctl show 2>/dev/null | awk -F': ' '/Powered|Name/ { print "  " $1 ": " $2 }'
    fi

    if command -v wpctl >/dev/null 2>&1; then
        printf '\n'
        ojuny_heading 'Audio'
        printf '  output:    %s\n' "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
        printf '  input:     %s\n' "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"
    fi

    printf '\n'
    ojuny_heading 'Backends'
    local command
    for command in dms mmsg nmcli mmcli bluetoothctl wpctl playerctl rfkill \
        udisksctl systemctl loginctl journalctl sbctl upower wtype ydotool \
        nix nixos-rebuild nixos-option nix-settings-gui git jq socat coredumpctl; do
        support_backend_line "$command"
    done

    printf '\n'
    ojuny_heading 'Patches'
    ojuny_print_patch_state 2>/dev/null | sed 's/^/  /' || true

    printf '\n'
    ojuny_heading 'Paths'
    printf '  nix-settings-gui: %s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json"
    printf '  wireguard:        %s\n' "${OJUNY_WIREGUARD_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ojuny/wireguard}"
    printf '  state:            %s\n' "$(ojuny_state_dir)"

    local log
    log="$(debug_log_path)"
    if [ -f "$log" ]; then
        printf '\n'
        ojuny_heading 'Debug log (tail)'
        tail -n 40 "$log" | sed 's/^/  /'
    fi

    printf '\n'
    ojuny_heading 'Failed units'
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user --failed --no-pager --no-legend 2>/dev/null | sed 's/^/  /' || true
    fi

    printf '\n'
    ojuny_heading 'Journal (tail)'
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --user -n 20 --no-pager 2>/dev/null | sed 's/^/  /' || true
    fi
}

support_json() {
    local status_json de flake host
    status_json="$(OJUNY_JSON=1 cmd_status 2>/dev/null | jq -c '.' 2>/dev/null || printf '{}')"
    de="$(support_de_wm)"
    flake="$(ojuny_flake_root 2>/dev/null)" || flake="unknown"
    host="$(ojuny_host_name 2>/dev/null)" || host="unknown"

    jq -cn --argjson status "$status_json" --arg de "$de" --arg flake "$flake" --arg host "$host" \
        --arg state "$(ojuny_state_dir)" \
        '{status:$status,de_wm:$de,flake:$flake,host:$host,state:$state}'
}

support_cmd() {
    if ojuny_is_json; then
        support_json
        return 0
    fi
    support_render | ojuny_redact
}
