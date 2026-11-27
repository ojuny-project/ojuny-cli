ojuny_environment_reload_command() {
    local cfg

    if [ -n "${OJUNY_ENVIRONMENT_RELOAD:-}" ]; then
        printf '%s\n' "$OJUNY_ENVIRONMENT_RELOAD"
        return 0
    fi

    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json"
    if [ -r "$cfg" ] && command -v jq >/dev/null 2>&1; then
        jq -r '.environment_reload_command // empty' "$cfg" 2>/dev/null || true
    fi
}

ojuny_run_environment_reload() {
    local command status=0 before stamp
    stamp="${XDG_RUNTIME_DIR:-/tmp}/ojuny-shell-reloaded"
    before="$(cat "$stamp" 2>/dev/null || true)"
    command="$(ojuny_environment_reload_command)"
    [ -n "$command" ] || return 0
    ojuny_exec bash -lc "$command" || status=$?
    if [ "$status" -eq 0 ]; then
        case "$command" in
        *dms*) ojuny_wait_for_dms "$before" || true ;;
        esac
    fi
    return "$status"
}

ojuny_wait_for_dms() {
    local before="${1:-}"
    local timeout="${OJUNY_DMS_READY_TIMEOUT:-10}"
    local stamp deadline now

    stamp="${XDG_RUNTIME_DIR:-/tmp}/ojuny-shell-reloaded"
    deadline=$((SECONDS + timeout))
    while [ "$SECONDS" -lt "$deadline" ]; do
        now="$(cat "$stamp" 2>/dev/null || true)"
        if [ -n "$now" ] && [ "$now" != "$before" ]; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

ojuny_rebuild_splash_has_socket() {
    local dir="${XDG_RUNTIME_DIR:-/tmp}/ojuny-login-splash" sock

    for sock in "$dir"/*.sock; do
        [ -e "$sock" ] && return 0
    done
    return 1
}

ojuny_rebuild_splash_stop_login() {
    [ "${OJUNY_REBUILD_SPLASH:-1}" = "0" ] && return 0
    if command -v systemctl >/dev/null 2>&1 && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
        systemctl --user stop ojuny-login-splash >/dev/null 2>&1 || true
    fi
    if command -v ojuny-login-splash >/dev/null 2>&1 && ojuny_rebuild_splash_has_socket; then
        timeout "${OJUNY_SPLASH_QUIT_TIMEOUT:-5}" ojuny-login-splash --quit >/dev/null 2>&1 || true
    fi
}

ojuny_rebuild_splash_start() {
    [ "${OJUNY_REBUILD_SPLASH:-1}" = "0" ] && return 0
    local splash

    if command -v systemctl >/dev/null 2>&1 && [ -n "${XDG_RUNTIME_DIR:-}" ] &&
        systemctl --user cat ojuny-login-splash.service >/dev/null 2>&1; then
        systemctl --user reset-failed ojuny-login-splash.service >/dev/null 2>&1 || true
        systemctl --user restart ojuny-login-splash.service >/dev/null 2>&1 || true
        systemctl --user restart ojuny-login-splash-ready.service >/dev/null 2>&1 || true
        OJUNY_SPLASH_STARTED=1
        return 0
    fi

    splash="$(command -v ojuny-login-splash || true)"
    if [ -z "$splash" ]; then
        ojuny_err "ojuny-login-splash not found; rebuild splash skipped"
        return 0
    fi
    "$splash" --seconds "${OJUNY_SPLASH_SECONDS:-60}" >/dev/null 2>&1 &
    OJUNY_SPLASH_STARTED=1
}

ojuny_rebuild_splash_stop() {
    [ "${OJUNY_SPLASH_STARTED:-0}" = "1" ] || return 0
    local splash i

    if command -v systemctl >/dev/null 2>&1 && [ -n "${XDG_RUNTIME_DIR:-}" ] &&
        systemctl --user cat ojuny-login-splash.service >/dev/null 2>&1; then
        systemctl --user stop ojuny-login-splash.service >/dev/null 2>&1 || true
    fi

    splash="$(command -v ojuny-login-splash || true)"
    if [ -n "$splash" ]; then
        for i in {1..20}; do
            ojuny_rebuild_splash_has_socket && break
            sleep 0.1
        done
        timeout "${OJUNY_SPLASH_QUIT_TIMEOUT:-5}" "$splash" --quit >/dev/null 2>&1 || true
    fi
    OJUNY_SPLASH_STARTED=0
}

ojuny_rebuild_hold_enabled() {
    case "${OJUNY_REBUILD_HOLD:-auto}" in
    0) return 1 ;;
    1) return 0 ;;
    esac
    ojuny_is_json && return 1
    ojuny_is_dry_run && return 1
    [ -t 0 ] && [ -t 2 ]
}

ojuny_rebuild_hold() {
    ojuny_rebuild_hold_enabled || return 0
    if [ -n "${OJUNY_REBUILD_HOLD_COMMAND:-}" ]; then
        ojuny_exec bash -lc "$OJUNY_REBUILD_HOLD_COMMAND" || true
        return 0
    fi
    printf '\nPress Enter to close...' >&2
    read -r _ || true
}

ojuny_rebuild_exec() {
    local mode="$1" flake="$2" host="$3"
    local status

    if ojuny_is_dry_run; then
        printf 'ojuny: dry-run: nixos-rebuild %s --flake %q |& nom\n' "$mode" "$flake#$host" >&2
        return 0
    fi

    set +e
    nixos-rebuild "$mode" --flake "$flake#$host" |& nom
    status=$?
    set -e
    return "$status"
}

rebuild_run() {
    local mode="$1" flake host status=0

    ojuny_require_command nom
    flake="$(ojuny_flake_root)" || return
    host="$(ojuny_host_name)" || return

    ojuny_flake_context pending
    ojuny_rebuild_exec "$mode" "$flake" "$host" || status=$?
    if [ "$status" -eq 0 ]; then
        ojuny_rebuild_splash_stop_login
        ojuny_rebuild_splash_start
        ojuny_run_environment_reload || status=$?
        ojuny_rebuild_splash_stop
    fi
    ojuny_flake_result "$status"
    ojuny_rebuild_hold
    return "$status"
}

rebuild_switch() {
    rebuild_run switch
}

rebuild_boot() {
    rebuild_run boot
}

rebuild_rollback() {
    local status=0

    flake_rollback "$@" || status=$?
    if [ "$status" -eq 0 ]; then
        ojuny_rebuild_splash_stop_login
        ojuny_rebuild_splash_start
        ojuny_run_environment_reload || status=$?
        ojuny_rebuild_splash_stop
    fi
    ojuny_rebuild_hold
    return "$status"
}

rebuild_subtree() {
    local command hold="${OJUNY_REBUILD_HOLD:-auto}"

    while [ "${1:-}" = "--hold" ] || [ "${1:-}" = "--no-hold" ]; do
        case "$1" in
        --hold) hold=1 ;;
        --no-hold) hold=0 ;;
        esac
        shift
    done
    export OJUNY_REBUILD_HOLD="$hold"
    command="${1:-}"
    shift || true

    case "$command" in
    switch) rebuild_switch ;;
    boot) rebuild_boot ;;
    rollback) rebuild_rollback "$@" ;;
    "")
        rebuild_switch
        ;;
    *)
        ojuny_usage_error "usage: ojuny rebuild [--hold|--no-hold] [switch|boot|rollback [generation]]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
