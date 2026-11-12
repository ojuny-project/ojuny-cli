OJUNY_EXIT_OK=0
OJUNY_EXIT_USAGE=2
OJUNY_EXIT_DEPENDENCY=3
OJUNY_EXIT_BACKEND=4
OJUNY_EXIT_VALIDATION=5
OJUNY_EXIT_CONFLICT=6

ojuny_err() {
    printf 'ojuny: %s\n' "$*" >&2
}

ojuny_die() {
    local code="$1"
    shift
    ojuny_err "$*"
    exit "$code"
}

ojuny_require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        ojuny_die "$OJUNY_EXIT_DEPENDENCY" "missing required command: $1"
}

ojuny_require_session_command() {
    local command="$1"
    if command -v "$command" >/dev/null 2>&1; then
        return 0
    fi
    ojuny_err "missing required command: $command"
    printf '  hint: %s is provided by the desktop session; run this from the Mango session or add its bin directory to PATH\n' "$command" >&2
    exit "$OJUNY_EXIT_DEPENDENCY"
}

ojuny_probe() {
    "$@" 2>/dev/null || true
}

ojuny_confirm() {
    local prompt="$1"
    local answer

    if [ "${OJUNY_YES:-0}" -eq 1 ]; then
        return 0
    fi

    if [ ! -t 0 ]; then
        ojuny_err "refusing to continue without --yes"
        return 1
    fi

    printf '%s [y/N] ' "$prompt" >&2
    read -r answer

    case "$answer" in
    y | Y | yes | YES) return 0 ;;
    *) return 1 ;;
    esac
}

ojuny_exec() {
    if command -v ojuny_debug_log >/dev/null 2>&1; then
        ojuny_debug_log "exec: $(printf '%q ' "$@")"
    fi

    if ojuny_is_verbose; then
        printf 'ojuny: exec:' >&2
        printf ' %q' "$@" >&2
        printf '\n' >&2
    fi

    if ojuny_is_dry_run; then
        printf 'ojuny: dry-run:' >&2
        printf ' %q' "$@" >&2
        printf '\n' >&2
        return 0
    fi

    "$@"
}

ojuny_exec_quiet() {
    if command -v ojuny_debug_log >/dev/null 2>&1; then
        ojuny_debug_log "exec: $(printf '%q ' "$@")"
    fi

    if ojuny_is_verbose || ojuny_is_dry_run; then
        ojuny_exec "$@"
        return
    fi
    "$@" >/dev/null
}

ojuny_print_version() {
    printf '%s %s\n' "$(basename "$0")" "${OJUNY_VERSION:-unknown}"
}

ojuny_usage_error() {
    ojuny_err "$*"
    return "$OJUNY_EXIT_USAGE"
}

ojuny_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

ojuny_join_by() {
    local separator="$1"
    shift
    local first=1 value
    for value in "$@"; do
        if [ "$first" -eq 1 ]; then
            printf '%s' "$value"
            first=0
        else
            printf '%s%s' "$separator" "$value"
        fi
    done
}

ojuny_sudo_hint() {
    local action="$1"
    printf '  hint: sudo ojuny %s\n' "$action" >&2
}

ojuny_require_root() {
    local action="$1"
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "permission denied for system scope"
        ojuny_sudo_hint "$action"
        return "$OJUNY_EXIT_VALIDATION"
    fi
}
