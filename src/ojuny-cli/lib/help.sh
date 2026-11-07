ojuny_usage() {
    ojuny_help_usage
}

ojuny_category_help() {
    local category="${1:-}"
    if [ -z "$category" ]; then
        ojuny_help_usage
        return 0
    fi
    ojuny_help_category "$category"
}

help_cmd() {
    local category="${1:-}"
    local command="${2:-}"

    if [ -z "$category" ]; then
        ojuny_help_usage
        return 0
    fi

    if [ -n "$command" ]; then
        ojuny_help_command "$category" "$command"
        return $?
    fi

    if [ -n "$(ojuny_top_handler "$category")" ]; then
        ojuny_help_top "$category"
        return $?
    fi

    ojuny_help_category "$category"
}

version_cmd() {
    ojuny_print_version
}
