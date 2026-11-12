dispatch_subtree() {
    local dispatcher="${1:-}"

    if [ -z "$dispatcher" ]; then
        ojuny_usage_error "usage: ojuny dispatch <dispatcher> [arguments]"
        return "$OJUNY_EXIT_USAGE"
    fi
    shift

    ojuny_require_session_command mmsg
    if [ "$#" -eq 0 ]; then
        mmsg dispatch "$dispatcher"
    else
        local IFS=,
        mmsg dispatch "$dispatcher,$*"
    fi
}
