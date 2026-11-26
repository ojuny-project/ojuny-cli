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
    local command
    command="$(ojuny_environment_reload_command)"
    [ -n "$command" ] || return 0
    ojuny_exec bash -lc "$command"
}

ojuny_rebuild_splash_start() {
    [ "${OJUNY_REBUILD_SPLASH:-1}" = "0" ] && return 0
    command -v ojuny-login-splash >/dev/null 2>&1 || return 0
    ojuny-login-splash --seconds "${OJUNY_SPLASH_SECONDS:-600}" >/dev/null 2>&1 &
    OJUNY_SPLASH_STARTED=1
}

ojuny_rebuild_splash_stop() {
    [ "${OJUNY_SPLASH_STARTED:-0}" = "1" ] || return 0
    command -v ojuny-login-splash >/dev/null 2>&1 || return 0
    ojuny-login-splash --quit >/dev/null 2>&1 || true
    OJUNY_SPLASH_STARTED=0
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
    local mode="$1" flake host status

    ojuny_require_command nom
    flake="$(ojuny_flake_root)" || return
    host="$(ojuny_host_name)" || return

    ojuny_flake_context pending
    ojuny_rebuild_exec "$mode" "$flake" "$host"
    status=$?
    if [ "$status" -eq 0 ] && [ -n "$(ojuny_environment_reload_command)" ]; then
        ojuny_rebuild_splash_start
        ojuny_run_environment_reload || status=$?
        ojuny_rebuild_splash_stop
    fi
    ojuny_flake_result "$status"
    return "$status"
}

rebuild_switch() {
    rebuild_run switch
}

rebuild_boot() {
    rebuild_run boot
}

rebuild_rollback() {
    local status
    flake_rollback "$@" || return
    if [ -n "$(ojuny_environment_reload_command)" ]; then
        ojuny_rebuild_splash_start
        ojuny_run_environment_reload || status=$?
        ojuny_rebuild_splash_stop
    fi
    return "${status:-0}"
}

rebuild_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    switch) rebuild_switch ;;
    boot) rebuild_boot ;;
    rollback) rebuild_rollback "$@" ;;
    "") rebuild_switch ;;
    *)
        ojuny_usage_error "usage: ojuny rebuild [switch|boot|rollback [generation]]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
