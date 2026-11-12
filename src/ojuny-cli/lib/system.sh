ojuny_session_field() {
    local session="$1"
    local field="$2"
    ojuny_probe loginctl show-session "$session" -p "$field" --value | head -n 1
}

ojuny_graphical_session_id() {
    if [ -n "${XDG_SESSION_ID:-}" ]; then
        case "$(ojuny_session_field "$XDG_SESSION_ID" Type)" in
        wayland | x11)
            if [ "$(ojuny_session_field "$XDG_SESSION_ID" Active)" = "yes" ]; then
                printf '%s\n' "$XDG_SESSION_ID"
                return 0
            fi
            ;;
        esac
    fi

    local candidate id
    local -a candidates=()
    candidate="$(ojuny_probe loginctl list-sessions --no-legend | awk -v uid="$(id -u)" '$2 == uid { print $1 }')"
    readarray -t candidates <<<"$candidate" || true
    for id in "${candidates[@]}"; do
        [ "$(ojuny_session_field "$id" Active)" = "yes" ] || continue
        [ "$(ojuny_session_field "$id" Remote)" = "no" ] || continue
        [ "$(ojuny_session_field "$id" Seat)" = "seat0" ] || continue
        case "$(ojuny_session_field "$id" Type)" in
        wayland | x11)
            printf '%s\n' "$id"
            return 0
            ;;
        esac
    done
    return 1
}

ojuny_session_summary() {
    local session_type="unknown" remote="unknown"
    if [ -n "${XDG_SESSION_ID:-}" ]; then
        session_type="$(ojuny_session_field "$XDG_SESSION_ID" Type)"
        remote="$(ojuny_session_field "$XDG_SESSION_ID" Remote)"
    fi
    printf '%s (wayland=%s, remote=%s)\n' "${session_type:-unknown}" "${WAYLAND_DISPLAY:-none}" "${remote:-unknown}"
}

system_lock() {
    local session
    ojuny_require_command loginctl
    session="$(ojuny_graphical_session_id)" || {
        ojuny_err "no active graphical session to lock"
        printf '  hint: run this from the desktop session\n' >&2
        return "$OJUNY_EXIT_VALIDATION"
    }
    ojuny_exec loginctl lock-session "$session"
}

system_logout() {
    ojuny_require_command loginctl
    [ -n "${XDG_SESSION_ID:-}" ] || ojuny_die "$OJUNY_EXIT_VALIDATION" "XDG_SESSION_ID is not set"
    loginctl terminate-session "$XDG_SESSION_ID"
}

system_suspend() {
    ojuny_require_command systemctl
    systemctl suspend
}

system_hibernate() {
    ojuny_require_command systemctl
    systemctl hibernate
}

system_reboot() {
    ojuny_require_command systemctl
    systemctl reboot
}

system_shutdown() {
    ojuny_require_command systemctl
    systemctl poweroff
}
