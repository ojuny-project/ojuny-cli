flake_status() {
    ojuny_flake_context ok
    ojuny_print_patch_state || true
}

flake_update() {
    if [ "$#" -lt 1 ]; then
        ojuny_err "flake update: an input is required"
        printf '  hint: ojuny flake update nixpkgs\n' >&2
        return "$OJUNY_EXIT_USAGE"
    fi

    local input
    for input in "$@"; do
        if [ -z "$(ojuny_trim "$input")" ]; then
            ojuny_err "flake update: an input is required"
            printf '  hint: ojuny flake update nixpkgs\n' >&2
            return "$OJUNY_EXIT_USAGE"
        fi
    done

    local flake
    flake="$(ojuny_flake_root)" || return
    ojuny_flake_context pending

    local status=0
    for input in "$@"; do
        nix_flake_update "$flake" "$input" || status=$?
        [ "$status" -eq 0 ] || break
    done
    ojuny_flake_result "$status"
    return "$status"
}

flake_validate() {
    local flake host status failed
    flake="$(ojuny_flake_root)" || return
    host="$(ojuny_host_name)" || return
    status=0
    failed=""

    nix_flake_check "$flake" || {
        status=$?
        failed="nix flake check"
    }
    if [ "$status" -eq 0 ]; then
        nixos_dry_build "$flake" "$host" || {
            status=$?
            failed="nixos-rebuild dry-build"
        }
    fi
    ojuny_flake_context "$([ "$status" -eq 0 ] && printf ok || printf failed)"
    if ! ojuny_print_patch_state; then
        [ "$status" -ne 0 ] || status=1
    fi
    if [ -n "$failed" ]; then
        printf '  failed: %s\n' "$failed"
    fi
    return "$status"
}

flake_build() {
    local flake host serial=0
    local -a extra=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --serial)
            serial=1
            shift
            ;;
        *)
            ojuny_usage_error "usage: ojuny flake build [--serial]"
            return "$OJUNY_EXIT_USAGE"
            ;;
        esac
    done

    flake="$(ojuny_flake_root)" || return
    host="$(ojuny_host_name)" || return
    [ "$serial" -eq 1 ] && extra=(--option max-jobs 1)

    ojuny_flake_context pending
    local status=0
    nixos_build "$flake" "$host" "${extra[@]}" || status=$?
    ojuny_flake_result "$status"
    return "$status"
}

flake_activate() {
    local flake host mode="boot"
    local -a extra=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --boot)
            mode="boot"
            shift
            ;;
        --now)
            mode="now"
            shift
            ;;
        *)
            ojuny_usage_error "usage: ojuny flake activate [--boot|--now]"
            return "$OJUNY_EXIT_USAGE"
            ;;
        esac
    done

    flake="$(ojuny_flake_root)" || return
    host="$(ojuny_host_name)" || return

    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "flake activate requires root"
        if [ "$mode" = "now" ]; then
            ojuny_sudo_hint "flake activate --now"
        else
            ojuny_sudo_hint "flake activate --boot"
        fi
        return "$OJUNY_EXIT_VALIDATION"
    fi

    ojuny_flake_context pending
    local status=0
    if [ "$mode" = "now" ]; then
        nixos_activate_now "$flake" "$host" "${extra[@]}" || status=$?
    else
        nixos_activate_boot "$flake" "$host" "${extra[@]}" || status=$?
    fi
    ojuny_flake_result "$status"
    return "$status"
}

flake_rollback() {
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "flake rollback requires root"
        ojuny_sudo_hint "flake rollback"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    local status=0
    nixos_rollback "$@" || status=$?
    return "$status"
}

flake_generations() {
    ojuny_require_command nixos-rebuild
    nixos_generations
}

flake_gc() {
    if [ "$(id -u)" -ne 0 ]; then
        ojuny_err "flake gc requires root for the system profile"
        ojuny_sudo_hint "flake gc"
        return "$OJUNY_EXIT_VALIDATION"
    fi

    local -a args=(-d)
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --dry-run) args=(--dry-run) ;;
        *)
            ojuny_usage_error "usage: ojuny flake gc [--dry-run]"
            return "$OJUNY_EXIT_USAGE"
            ;;
        esac
        shift
    done

    ojuny_exec nix_collect_garbage "${args[@]}"
}

flake_option() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny flake option <path>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_command nixos-option
    nixos_option "$1"
}

flake_subtree() {
    local command="${1:-}"
    shift || true

    case "$command" in
    status) flake_status ;;
    update) flake_update "$@" ;;
    validate) flake_validate ;;
    build) flake_build "$@" ;;
    activate) flake_activate "$@" ;;
    rollback) flake_rollback "$@" ;;
    generations) flake_generations ;;
    gc) flake_gc "$@" ;;
    option) flake_option "$@" ;;
    "")
        flake_status
        ;;
    *)
        ojuny_usage_error "usage: ojuny flake <status|update|validate|build|activate|rollback|generations|gc|option>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
