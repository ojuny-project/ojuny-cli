workspace_current() {
    local data
    data="$(mmsg get all-monitors | jq -c '[.monitors[] | select(.active == true) | {monitor: .name, workspace: (.tags[] | select(.is_active == true) | .index)}]')"

    if ojuny_is_json; then
        printf '%s\n' "$data"
        return 0
    fi

    printf '%s' "$data" | jq -r '.[] | "\(.monitor)\t\(.workspace)"' | ojuny_kv_block
}

workspace_view() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny workspace view <id>"
        return "$OJUNY_EXIT_USAGE"
    fi
    msetworkspace "$1"
}

workspace_toggle() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny workspace toggle <id>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mtoggleworkspace "$1"
}

workspace_move() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny workspace move <id>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mtagsilent "$1"
}

workspace_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    current) workspace_current ;;
    view) workspace_view "$@" ;;
    toggle) workspace_toggle "$@" ;;
    move) workspace_move "$@" ;;
    next) mviewtoright 0 ;;
    previous) mviewtoleft 0 ;;
    next-client) mviewnextclient ;;
    previous-client) mviewprevclient ;;
    "")
        workspace_current
        ;;
    *)
        ojuny_usage_error "usage: ojuny workspace <command>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
