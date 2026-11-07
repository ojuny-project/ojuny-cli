OJUNY_ARGS=()
OJUNY_HELP=0
OJUNY_VERSION_FLAG=0
OJUNY_JSON="${OJUNY_JSON:-0}"
OJUNY_QUIET="${OJUNY_QUIET:-0}"
OJUNY_VERBOSE="${OJUNY_VERBOSE:-0}"
OJUNY_NO_COLOR="${OJUNY_NO_COLOR:-0}"
OJUNY_YES="${OJUNY_YES:-0}"
OJUNY_DRY_RUN="${OJUNY_DRY_RUN:-0}"
OJUNY_SYSTEM="${OJUNY_SYSTEM:-0}"
OJUNY_FLAKE="${OJUNY_FLAKE:-}"
OJUNY_HOST="${OJUNY_HOST:-}"

ojuny_parse_global_options() {
    OJUNY_ARGS=()
    local passthrough=0

    while [ "$#" -gt 0 ]; do
        if [ "$passthrough" -eq 0 ]; then
            case "$1" in
            --json)
                OJUNY_JSON=1
                shift
                continue
                ;;
            --quiet)
                OJUNY_QUIET=1
                shift
                continue
                ;;
            --verbose)
                OJUNY_VERBOSE=1
                shift
                continue
                ;;
            --no-color)
                OJUNY_NO_COLOR=1
                shift
                continue
                ;;
            --yes | -y)
                OJUNY_YES=1
                shift
                continue
                ;;
            --dry-run)
                OJUNY_DRY_RUN=1
                shift
                continue
                ;;
            --system)
                OJUNY_SYSTEM=1
                shift
                continue
                ;;
            -h | --help)
                OJUNY_HELP=1
                shift
                continue
                ;;
            -V | --version)
                OJUNY_VERSION_FLAG=1
                shift
                continue
                ;;
            --flake)
                [ "$#" -ge 2 ] || ojuny_die "$OJUNY_EXIT_USAGE" "--flake requires a path"
                OJUNY_FLAKE="$2"
                shift 2
                continue
                ;;
            --host)
                [ "$#" -ge 2 ] || ojuny_die "$OJUNY_EXIT_USAGE" "--host requires a name"
                OJUNY_HOST="$2"
                shift 2
                continue
                ;;
            --)
                passthrough=1
                shift
                continue
                ;;
            esac
        fi

        OJUNY_ARGS+=("$1")
        shift
    done
}

ojuny_is_json() {
    [ "${OJUNY_JSON:-0}" -eq 1 ]
}

ojuny_is_quiet() {
    [ "${OJUNY_QUIET:-0}" -eq 1 ]
}

ojuny_is_verbose() {
    [ "${OJUNY_VERBOSE:-0}" -eq 1 ]
}

ojuny_is_dry_run() {
    [ "${OJUNY_DRY_RUN:-0}" -eq 1 ]
}

ojuny_system_scope() {
    [ "${OJUNY_SYSTEM:-0}" -eq 1 ]
}

ojuny_need_args() {
    local required="$1"
    shift
    [ "$#" -ge "$required" ]
}
