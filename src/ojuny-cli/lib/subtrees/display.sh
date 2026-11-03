display_subtree() {
    case "${1:-}" in
    list | current)
        ojuny_require_command mmsg
        mmsg get all-monitors
        ;;
    resolution | toggle | sleep)
        ojuny_err "display $1 is a persistent setting; use 'ojuny settings open displays'"
        return "$OJUNY_EXIT_VALIDATION"
        ;;
    *)
        ojuny_err "usage: ojuny display <list|current|resolution|toggle|sleep>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
