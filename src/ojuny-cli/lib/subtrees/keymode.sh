keymode_get() {
    local data
    data="$(mmsg get keymode)"
    if ojuny_is_json; then
        printf '%s\n' "$data"
        return 0
    fi
    printf '%s' "$data" | jq -r '.keymode'
}

keymode_set() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny keymode set <mode>"
        return "$OJUNY_EXIT_USAGE"
    fi
    mkeymode "$1"
}

keymode_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    get) keymode_get ;;
    set) keymode_set "$@" ;;
    "")
        keymode_get
        ;;
    *)
        ojuny_usage_error "usage: ojuny keymode <get|set>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
