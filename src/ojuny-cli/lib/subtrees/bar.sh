bar_apply() {
    local output status
    set +e
    output="$("$@")"
    status=$?
    set -e
    if [ "$status" -ne 0 ]; then
        [ -z "$output" ] || printf '%s\n' "$output"
        return "$status"
    fi
    if printf '%s' "$output" | grep -q 'BAR_IS_ISLAND'; then
        ojuny_err "bar: island bars do not support hide or show"
        return "$OJUNY_EXIT_BACKEND"
    fi
    [ -z "$output" ] || printf '%s\n' "$output"
}

bar_toggle() {
    bar_apply dux_bar_toggle
}

bar_show() {
    bar_apply dux_bar_reveal
}

bar_hide() {
    bar_apply dux_bar_hide
}

bar_subtree() {
    case "${1:-}" in
    toggle)
        shift
        bar_toggle "$@"
        ;;
    show)
        shift
        bar_show "$@"
        ;;
    hide)
        shift
        bar_hide "$@"
        ;;
    "")
        bar_toggle
        ;;
    *)
        ojuny_usage_error "usage: ojuny bar <toggle|show|hide>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
