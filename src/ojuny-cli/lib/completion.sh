ojuny_completion_categories() {
    awk -F '\t' '$1 == "cat" { print $2 }' "$(ojuny_commands_file)" | paste -sd' ' -
}

ojuny_completion_top() {
    awk -F '\t' '$1 == "top" { print $2 }' "$(ojuny_commands_file)" | paste -sd' ' -
}

ojuny_completion_subcommands() {
    awk -F '\t' -v category="$1" \
        '$1 == "cmd" && $2 ~ ("^" category "\\.") { sub("^" category "\\.", "", $2); print $2 }' \
        "$(ojuny_commands_file)" | paste -sd' ' -
}

ojuny_completion_source() {
    local category="$1"
    local command="$2"
    local source

    source="$(ojuny_command_field cmd "$category.$command" completion)"
    if [ -n "$source" ] && [ "$source" != "-" ]; then
        printf '%s\n' "$source"
        return 0
    fi

    case "$category.$command" in
    vpn.up | vpn.down) printf 'vpn\n' ;;
    wifi.connect) printf 'wifi\n' ;;
    network.connect) printf 'connections\n' ;;
    bluetooth.connect | bluetooth.pair | bluetooth.trust | bluetooth.remove) printf 'devices\n' ;;
    disk.mount | disk.unmount | disk.eject) printf 'disks\n' ;;
    esac
}

ojuny_completion_dynamic() {
    local source="$1"
    case "$source" in
    vpn)
        command -v nmcli >/dev/null 2>&1 || return 0
        nmcli -t -f NAME,TYPE connection show 2>/dev/null |
            awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1 }'
        ;;
    connections)
        command -v nmcli >/dev/null 2>&1 || return 0
        nmcli -t -f NAME connection show 2>/dev/null | head -n 50
        ;;
    wifi)
        command -v nmcli >/dev/null 2>&1 || return 0
        nmcli -t -f SSID device wifi list 2>/dev/null | awk 'NF { print }' | sort -u
        ;;
    devices)
        command -v bluetoothctl >/dev/null 2>&1 || return 0
        bluetoothctl devices 2>/dev/null | awk '{ print $2 }'
        ;;
    pages)
        ojuny_settings_pages 2>/dev/null | cut -f1
        ;;
    units)
        local scope="--user"
        [ "$(id -u)" -eq 0 ] && scope=""
        command -v systemctl >/dev/null 2>&1 || return 0
        systemctl $scope list-unit-files --type=service --no-legend --no-pager 2>/dev/null |
            awk '{ print $1 }' | head -n 100
        ;;
    disks)
        command -v lsblk >/dev/null 2>&1 || return 0
        lsblk -ln -o PATH 2>/dev/null
        ;;
    inputs)
        ojuny_flake_root >/dev/null 2>&1 || return 0
        (cd "$(ojuny_flake_root)" && nix flake metadata --json 2>/dev/null) |
            jq -r '.locks.nodes.root.inputs | keys[]' 2>/dev/null
        ;;
    generations)
        command -v nixos-rebuild >/dev/null 2>&1 || return 0
        nixos-rebuild list-generations 2>/dev/null | awk '/^[0-9]+/ { print $1 }'
        ;;
    methods)
        ojuny commands --json 2>/dev/null | jq -r '.data.commands[] | select(.kind != "cat") | .path' 2>/dev/null
        ;;
    topics)
        printf '%s\n' status network wifi bluetooth audio media vpn battery dnd night
        ;;
    esac
}

complete_cmd() {
    local category="$1"
    local command="${2:-}"
    local source

    if [ -n "$command" ]; then
        source="$(ojuny_completion_source "$category" "$command")"
    else
        source="$(ojuny_command_field top "$category" completion)"
        if [ -z "$source" ] || [ "$source" = "-" ]; then
            source="$(ojuny_command_field cat "$category" completion)"
        fi
        [ "$source" = "-" ] && source=""
    fi

    [ -n "$source" ] || return 0
    ojuny_completion_dynamic "$source"
}

completions_cmd() {
    local shell="${1:-}"
    case "$shell" in
    bash) ojuny_completion_bash ;;
    zsh) ojuny_completion_zsh ;;
    fish) ojuny_completion_fish ;;
    *)
        ojuny_usage_error "usage: ojuny completions <bash|zsh|fish>"
        return "$OJUNY_EXIT_USAGE"
        ;;
    esac
}

ojuny_completion_bash() {
    local category commands
    printf '_ojuny() {\n'
    printf '    local cur category command candidates\n'
    printf '    COMPREPLY=()\n'
    printf '    cur="${COMP_WORDS[COMP_CWORD]}"\n'
    printf '    category="${COMP_WORDS[1]}"\n'
    printf '    if [ "$COMP_CWORD" -eq 1 ]; then\n'
    printf '        COMPREPLY=( $(compgen -W "%s %s" -- "$cur") )\n' \
        "$(ojuny_completion_top)" "$(ojuny_completion_categories)"
    printf '        return 0\n'
    printf '    fi\n'
    printf '    if [ "$COMP_CWORD" -eq 2 ]; then\n'
    printf '        case "$category" in\n'
    while IFS= read -r category; do
        commands="$(ojuny_completion_subcommands "$category")"
        [ -n "$commands" ] || continue
        printf '        %s) COMPREPLY=( $(compgen -W "%s" -- "$cur") ) ;;\n' "$category" "$commands"
    done < <(awk -F '\t' '$1 == "cat" { print $2 }' "$(ojuny_commands_file)")
    printf '        run) COMPREPLY=( $(compgen -c -- "$cur") ) ;;\n'
    printf '        esac\n'
    printf '        case "$category" in\n'
    printf '        settings | raw-settings | logs)\n'
    printf '            COMPREPLY=( $(compgen -W "$(ojuny __complete "$category" 2>/dev/null)" -- "$cur") )\n'
    printf '            ;;\n'
    printf '        esac\n'
    printf '    fi\n'
    printf '    if [ "$COMP_CWORD" -ge 3 ]; then\n'
    printf '        command="${COMP_WORDS[2]}"\n'
    printf '        candidates="$(ojuny __complete "$category" "$command" 2>/dev/null)"\n'
    printf '        if [ -n "$candidates" ]; then\n'
    printf '            COMPREPLY=( $(compgen -W "$candidates" -- "$cur") )\n'
    printf '        fi\n'
    printf '    fi\n'
    printf '}\n'
    printf 'complete -F _ojuny ojuny\n'
}

ojuny_completion_zsh() {
    local category commands summary
    printf '#compdef ojuny\n\n'
    printf '_ojuny() {\n'
    printf '    local -a commands values\n'
    printf '    if (( CURRENT == 2 )); then\n'
    printf '        commands=(\n'
    while IFS=$'\t' read -r category summary; do
        printf "            '%s:%s'\n" "$category" "$summary"
    done < <(ojuny_list_categories)
    while IFS=$'\t' read -r category summary; do
        printf "            '%s:%s'\n" "$category" "$summary"
    done < <(ojuny_list_top_commands)
    printf '        )\n'
    printf '        _describe "command" commands\n'
    printf '        return\n'
    printf '    fi\n'
    printf '    if (( CURRENT == 3 )) && [[ $words[2] == (settings|raw-settings|logs) ]]; then\n'
    printf '        values=("${(@f)$(ojuny __complete $words[2] 2>/dev/null)}")\n'
    printf '        (( $#values )) && _describe "value" values && return\n'
    printf '    fi\n'
    printf '    if (( CURRENT >= 4 )); then\n'
    printf '        values=("${(@f)$(ojuny __complete $words[2] $words[3] 2>/dev/null)}")\n'
    printf '        (( $#values )) && _describe "value" values && return\n'
    printf '    fi\n'
    printf '    if (( CURRENT == 3 )); then\n'
    printf '        case $words[2] in\n'
    while IFS=$'\t' read -r category summary; do
        commands="$(ojuny_completion_subcommands "$category")"
        [ -n "$commands" ] || continue
        printf '            %s) _values "command" %s ;;\n' "$category" "$commands"
    done < <(ojuny_list_categories)
    printf '            run) _command_names ;;\n'
    printf '        esac\n'
    printf '    fi\n'
    printf '}\n\n'
    printf '_ojuny "$@"\n'
}

ojuny_completion_fish() {
    local category summary commands command source
    while IFS=$'\t' read -r category summary; do
        printf "complete -c ojuny -f -n '__fish_use_subcommand' -a '%s' -d '%s'\n" "$category" "$summary"
    done < <(ojuny_list_categories)
    while IFS=$'\t' read -r category summary; do
        printf "complete -c ojuny -f -n '__fish_use_subcommand' -a '%s' -d '%s'\n" "$category" "$summary"
    done < <(ojuny_list_top_commands)
    for category in settings raw-settings logs; do
        printf "complete -c ojuny -f -n '__fish_seen_subcommand_from %s' -a '(ojuny __complete %s 2>/dev/null)'\n" \
            "$category" "$category"
    done
    printf "complete -c ojuny -f -n '__fish_seen_subcommand_from run' -a '(__fish_complete_commands)'\n"
    while IFS=$'\t' read -r category summary; do
        commands="$(ojuny_completion_subcommands "$category")"
        [ -n "$commands" ] || continue
        for command in $commands; do
            source="$(ojuny_completion_source "$category" "$command")"
            if [ -n "$source" ]; then
                printf "complete -c ojuny -f -n '__fish_seen_subcommand_from %s; and __fish_seen_subcommand_from %s' -a '(ojuny __complete %s %s 2>/dev/null)'\n" \
                    "$category" "$command" "$category" "$command"
            else
                printf "complete -c ojuny -f -n '__fish_seen_subcommand_from %s' -a '%s'\n" "$category" "$command"
            fi
        done
    done < <(ojuny_list_categories)
}
