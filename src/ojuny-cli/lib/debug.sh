ojuny_state_dir() {
    printf '%s/ojuny\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

debug_log_path() {
    printf '%s/debug.log\n' "$(ojuny_state_dir)"
}

debug_marker_path() {
    printf '%s/debug.enabled\n' "$(ojuny_state_dir)"
}

debug_enabled() {
    [ "${OJUNY_DEBUG:-0}" -eq 1 ] || [ -e "$(debug_marker_path)" ]
}

ojuny_redact() {
    sed -E \
        -e 's/(password|passwd|psk|private[_ -]?key|token|secret)([=: ]+)[^ ]+/\1\2[redacted]/Ig'
}

ojuny_debug_log() {
    local message="$1"
    local log line

    debug_enabled || return 0

    log="$(debug_log_path)"
    mkdir -p "$(dirname "$log")"
    chmod 700 "$(dirname "$log")"

    if [ -f "$log" ] && [ "$(wc -c <"$log")" -gt 1048576 ]; then
        mv "$log" "$log.1"
    fi

    line="$(printf '%s' "$message" | ojuny_redact)"
    printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$line" >>"$log"
    chmod 600 "$log"
}

debug_status() {
    local log marker
    log="$(debug_log_path)"
    marker="$(debug_marker_path)"

    if ojuny_is_json; then
        jq -cn --arg log "$log" --arg marker "$marker" --argjson enabled "$([ -e "$marker" ] && echo true || echo false)" \
            '{enabled:$enabled,log:$log,marker:$marker}'
        return 0
    fi

    printf 'enabled\t%s\n' "$([ -e "$marker" ] && echo yes || echo no)"
    printf 'log\t%s\n' "$log"
    [ -f "$log" ] && printf 'size\t%s bytes\n' "$(wc -c <"$log")"
}

debug_on() {
    local marker
    marker="$(debug_marker_path)"
    mkdir -p "$(dirname "$marker")"
    chmod 700 "$(dirname "$marker")"
    : >"$marker"
    chmod 600 "$marker"
    ojuny_ok "debug logging enabled"
}

debug_off() {
    local marker
    marker="$(debug_marker_path)"
    if [ -e "$marker" ]; then
        rm -f "$marker"
    fi
    ojuny_ok "debug logging disabled"
}

debug_tail() {
    local lines=50
    local log

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --lines | -n)
            [ "$#" -ge 2 ] || {
                ojuny_usage_error "--lines requires a value"
                return "$OJUNY_EXIT_USAGE"
            }
            lines="$2"
            shift 2
            ;;
        *)
            ojuny_usage_error "usage: ojuny debug tail [--lines N]"
            return "$OJUNY_EXIT_USAGE"
            ;;
        esac
    done

    log="$(debug_log_path)"
    if [ ! -f "$log" ]; then
        return 0
    fi
    tail -n "$lines" "$log"
}

debug_clear() {
    local log
    log="$(debug_log_path)"
    mkdir -p "$(dirname "$log")"
    : >"$log"
    chmod 600 "$log"
    ojuny_ok "debug log cleared"
}

debug_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) debug_status ;;
    on) debug_on ;;
    off) debug_off ;;
    tail) debug_tail "$@" ;;
    clear) debug_clear ;;
    "")
        debug_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny debug <status|on|off|tail|clear>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
