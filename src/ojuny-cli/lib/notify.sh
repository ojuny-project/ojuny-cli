notify_cmd() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny notify <summary> [body] [flags]"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command dms
    ojuny_exec dms notify "$@"
}
