input_type() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny input type <text>"
        return "$OJUNY_EXIT_USAGE"
    fi
    if command -v wtype >/dev/null 2>&1; then
        ojuny_exec wtype "$*"
    else
        ojuny_require_command ydotool
        ojuny_exec ydotool type "$*"
    fi
}

input_key() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny input key <combo>"
        return "$OJUNY_EXIT_USAGE"
    fi

    ojuny_require_command wtype
    local combo="$1"
    local -a args=()
    local part

    IFS='+' read -r -a parts <<<"$combo"
    local count="${#parts[@]}"
    local index=0

    for part in "${parts[@]}"; do
        index=$((index + 1))
        if [ "$index" -eq "$count" ]; then
            args+=(-k "$part")
        else
            case "$part" in
            ctrl | control) args+=(-M ctrl) ;;
            shift) args+=(-M shift) ;;
            alt | option) args+=(-M alt) ;;
            super | meta | win) args+=(-M logo) ;;
            *) args+=(-M "$part") ;;
            esac
        fi
    done

    ojuny_exec wtype "${args[@]}"
}

input_click() {
    ojuny_require_command ydotool
    local button="${1:-left}"
    local code
    case "$button" in
    left) code="0x00" ;;
    right) code="0x01" ;;
    middle) code="0x02" ;;
    *)
        ojuny_usage_error "usage: ojuny input click [left|right|middle]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
    ojuny_exec ydotool click "$code"
}

input_move() {
    if [ "$#" -lt 2 ]; then
        ojuny_usage_error "usage: ojuny input move <x> <y>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command ydotool
    ojuny_exec ydotool mousemove -a -x "$1" -y "$2"
}

input_scroll() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny input scroll <up|down|left|right> [amount]"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command ydotool
    local direction="$1"
    local amount="${2:-1}"
    local x=0 y=0
    case "$direction" in
    up) y="$amount" ;;
    down) y="-$amount" ;;
    left) x="-$amount" ;;
    right) x="$amount" ;;
    *)
        ojuny_usage_error "usage: ojuny input scroll <up|down|left|right> [amount]"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
    ojuny_exec ydotool mousemove -w -x "$x" -y "$y"
}

input_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    type) input_type "$@" ;;
    key) input_key "$@" ;;
    click) input_click "$@" ;;
    move) input_move "$@" ;;
    scroll) input_scroll "$@" ;;
    *)
        ojuny_usage_error "usage: ojuny input <type|key|click|move|scroll>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
