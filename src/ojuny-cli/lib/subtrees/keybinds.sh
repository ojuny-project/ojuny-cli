keybinds_open() {
    dux_keybinds_open
}

keybinds_list() {
    ojuny_require_session_command dms
    dms keybinds list
}

keybinds_show() {
    if [ "$#" -lt 1 ]; then
        ojuny_usage_error "usage: ojuny keybinds show <provider>"
        return "$OJUNY_EXIT_USAGE"
    fi
    ojuny_require_session_command dms
    dms keybinds show "$1"
}

keybinds_count() {
    local provider="${1:-binds}" data status=0 provider_name
    ojuny_require_session_command dms
    set +e
    data="$(dms keybinds show "$provider")"
    status=$?
    set -e
    [ "$status" -eq 0 ] || return "$status"

    if ! printf '%s' "$data" | jq -e '.binds' >/dev/null 2>&1; then
        ojuny_err "no binds returned for provider: $provider"
        return "$OJUNY_EXIT_BACKEND"
    fi

    if ojuny_is_json; then
        printf '%s' "$data" | jq -c --arg provider "$provider" \
            '{provider:(.provider // $provider),total:([.binds[][]] | length),categories:(.binds | with_entries(.value |= length))}'
        return 0
    fi

    provider_name="$(printf '%s' "$data" | jq -r '.provider // empty')"
    {
        [ -z "$provider_name" ] || printf 'provider\t%s\n' "$provider_name"
        printf '%s' "$data" | jq -r '.binds | to_entries[] | "\(.key)\t\(.value | length)"'
        printf 'total\t%s\n' "$(printf '%s' "$data" | jq '[.binds[][]] | length')"
    } | ojuny_kv_block
}

keybinds_subtree() {
    local command="${1:-open}"
    shift || true

    case "$command" in
    open) keybinds_open ;;
    list) keybinds_list ;;
    show) keybinds_show "$@" ;;
    count) keybinds_count "$@" ;;
    *)
        ojuny_usage_error "usage: ojuny keybinds <open|list|show|count>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}
