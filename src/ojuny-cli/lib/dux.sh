dux_call() {
    local object="$1"
    local method="$2"
    shift 2
    ojuny_require_session_command dms

    local output status
    set +e
    output="$(dms ipc call "$object" "$method" "$@")"
    status=$?
    set -e

    if [ "$status" -ne 0 ]; then
        [ -z "$output" ] || printf '%s\n' "$output"
        return "$status"
    fi
    if printf '%s' "$output" | grep -Eq 'Too few arguments|Too many arguments|^Error:|_FAILED$'; then
        printf '%s\n' "$output" >&2
        return "$OJUNY_EXIT_BACKEND"
    fi
    [ -z "$output" ] || printf '%s\n' "$output"
}

dux_ipc() {
    ojuny_require_session_command dms
    dms ipc "$@"
}

dux_start() {
    ojuny_require_session_command dms
    dms run
}

dux_stop() {
    ojuny_require_session_command dms
    dms kill
}

dux_restart() {
    ojuny_require_session_command dms
    dms kill
    if command -v mmsg >/dev/null 2>&1; then
        mdispatch spawn_shell "dms run"
    else
        dms run
    fi
}

dux_status() {
    ojuny_require_session_command dms
    dms version
}

dux_screenshot() {
    ojuny_require_session_command dms
    dms screenshot "$@"
}

dux_settings_open() {
    local page="$1"
    dux_call settings focusOrToggleWith "$page"
}

dux_network_open() {
    dux_settings_open network
}

dux_keybinds_open() {
    dux_call keybinds open binds
}

dux_clipboard_open() {
    dux_call clipboard toggle
}

dux_clipboard_clear() {
    dux_call clipboard clear
}

dux_notepad_toggle() {
    dux_call notepad toggle
}

dux_spotlight_toggle() {
    dux_call spotlight toggle
}

dux_spotlight_query() {
    dux_call spotlight toggleQuery "$1"
}

dux_controlcenter_toggle() {
    dux_call control-center toggle
}

dux_menu_toggle() {
    dux_call dankMenu toggle root
}

dux_bar_toggle() {
    dux_call bar toggle index 0
}

dux_bar_hide() {
    dux_call bar hide index 0
}

dux_bar_reveal() {
    dux_call bar reveal index 0
}

dux_settings_set() {
    dux_call settings set "$1" "$2"
}

dux_dock_toggle() {
    dux_call dock toggle
}

dux_inhibit_toggle() {
    dux_call inhibit toggle
}

dux_inhibit_status() {
    dux_call inhibit status
}

dux_night_toggle() {
    dux_call night toggle
}

dux_night_status() {
    dux_call night status
}

dux_dnd_toggle() {
    dux_call notifications toggleDoNotDisturb
}

dux_dashboard_open() {
    dux_call dash open "$1"
}

dux_dashboard_close() {
    dux_call dash close
}

dux_dashboard_toggle() {
    dux_call dash toggle "$1"
}

dux_island_open() {
    dux_call island open "$1"
}

dux_island_show() {
    dux_call island open "$1"
}

dux_island_cycle() {
    dux_call island cycle
}

dux_island_move() {
    dux_call island move "$@"
}

dux_island_center() {
    dux_call island center "$@"
}

dux_capture_toolbar() {
    dux_call screenCaptureToolbar toggle
}
