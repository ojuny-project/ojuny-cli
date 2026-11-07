layout_set() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny layout set <layout> [variant]"
        return "$OJUNY_EXIT_USAGE"
    fi
    msetlayout "$@"
}

layout_current() {
    mcurrentlayout
}

layout_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    set)
        layout_set "$@"
        ;;
    current)
        layout_current
        ;;
    "")
        layout_current
        ;;
    *)
        ojuny_usage_error "usage: ojuny layout <set|current>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
