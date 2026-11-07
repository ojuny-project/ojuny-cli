ojuny_commands_file() {
    printf '%s/commands.tsv\n' "$OJUNY_LIB_DIR"
}

ojuny_field_number() {
    case "$1" in
    kind) printf '1\n' ;;
    path) printf '2\n' ;;
    handler) printf '3\n' ;;
    usage) printf '4\n' ;;
    summary) printf '5\n' ;;
    class) printf '6\n' ;;
    backend) printf '7\n' ;;
    flags) printf '8\n' ;;
    completion) printf '9\n' ;;
    aliases) printf '10\n' ;;
    default) printf '11\n' ;;
    destructive) printf '12\n' ;;
    esac
}

ojuny_command_field() {
    local kind="$1"
    local path="$2"
    local name="$3"
    local number

    number="$(ojuny_field_number "$name")"
    awk -F '\t' -v kind="$kind" -v path="$path" -v number="$number" \
        '$1 == kind && $2 == path { print $number; exit }' "$(ojuny_commands_file)"
}

ojuny_category_handler() {
    ojuny_command_field cat "$1" handler
}

ojuny_top_handler() {
    ojuny_command_field top "$1" handler
}

ojuny_command_handler() {
    ojuny_command_field cmd "$1.$2" handler
}

ojuny_command_exists() {
    local kind="$1"
    local path="$2"
    [ -n "$(ojuny_command_field "$kind" "$path" summary)" ]
}

ojuny_default_subcommand() {
    awk -F '\t' -v category="$1" \
        '$1 == "cmd" && $2 ~ ("^" category "\\.") && $11 == "1" { sub("^" category "\\.", "", $2); print $2; exit }' \
        "$(ojuny_commands_file)"
}

ojuny_list_categories() {
    awk -F '\t' '$1 == "cat" { print $2 "\t" $5 }' "$(ojuny_commands_file)"
}

ojuny_list_top_commands() {
    awk -F '\t' '$1 == "top" { print $2 "\t" $5 }' "$(ojuny_commands_file)"
}

ojuny_list_commands() {
    awk -F '\t' -v category="$1" \
        '$1 == "cmd" && $2 ~ ("^" category "\\.") { sub("^" category "\\.", "", $2); print $2 "\t" $4 "\t" $5 }' \
        "$(ojuny_commands_file)"
}

ojuny_help_usage() {
    local path summary

    if ojuny_is_json; then
        local categories commands
        categories="$(awk -F '\t' '$1 == "cat" { printf "%s\t%s\n", $2, $5 }' "$(ojuny_commands_file)" |
            jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], summary: .[1]})')"
        commands="$(awk -F '\t' '$1 == "top" { printf "%s\t%s\n", $2, $5 }' "$(ojuny_commands_file)" |
            jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], summary: .[1]})')"
        jq -cn --argjson categories "$categories" --argjson commands "$commands" \
            '{schema:1,command:"help",ok:true,data:{usage:"ojuny [options] <category> [command] [args]",categories:$categories,commands:$commands},meta:{}}'
        return 0
    fi

    printf 'Usage: ojuny [options] <category> [command] [args]\n'
    printf '       ojuny [options] <command> [args]\n\n'
    ojuny_heading 'Commands'
    while IFS=$'\t' read -r path summary; do
        printf '  %-22s %s\n' "$path" "$summary"
    done < <(ojuny_list_top_commands)
    printf '\n'
    ojuny_heading 'Categories'
    while IFS=$'\t' read -r path summary; do
        printf '  %-22s %s\n' "$path" "$summary"
    done < <(ojuny_list_categories)
    printf '\nRun %s for category help.\n' "$(ojuny_dim 'ojuny help <category>')"
}

ojuny_help_category() {
    local category="$1"
    local summary handler aliases default
    summary="$(ojuny_command_field cat "$category" summary)"
    handler="$(ojuny_command_field cat "$category" handler)"

    if [ -z "$handler" ]; then
        ojuny_err "unknown category: $category"
        return "$OJUNY_EXIT_USAGE"
    fi

    aliases="$(ojuny_command_field cat "$category" aliases)"
    default="$(ojuny_default_subcommand "$category")"

    if ojuny_is_json; then
        local commands
        commands="$(ojuny_list_commands "$category" |
            jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], usage: .[1], summary: .[2]})')"
        jq -cn --arg category "$category" --arg summary "$summary" --arg default "$default" \
            --arg aliases "$aliases" --argjson commands "$commands" \
            '{schema:1,command:("help." + $category),ok:true,data:{category:$category,summary:$summary,default:$default,aliases:$aliases,commands:$commands},meta:{}}'
        return 0
    fi

    printf 'Usage: ojuny %s <command> [args]\n' "$category"
    [ -n "$summary" ] && printf '%s\n' "$summary"
    [ -n "$default" ] && printf 'Bare %s runs %s.\n' "$category" "$default"
    [ -n "$aliases" ] && [ "$aliases" != "-" ] && printf 'Aliases: %s\n' "$aliases"
    printf '\n'
    while IFS=$'\t' read -r name usage command_summary; do
        if [ -n "$usage" ] && [ "$usage" != "-" ]; then
            printf '  %-16s %-26s %s\n' "$name" "$usage" "$command_summary"
        else
            printf '  %-16s %-26s %s\n' "$name" "" "$command_summary"
        fi
    done < <(ojuny_list_commands "$category")
}

ojuny_help_command() {
    local category="$1"
    local command="$2"
    local path="$category.$command"
    local summary usage class backend destructive
    summary="$(ojuny_command_field cmd "$path" summary)"
    usage="$(ojuny_command_field cmd "$path" usage)"
    class="$(ojuny_command_field cmd "$path" class)"
    backend="$(ojuny_command_field cmd "$path" backend)"
    destructive="$(ojuny_command_field cmd "$path" destructive)"

    if [ -z "$summary" ]; then
        ojuny_err "unknown command: $category $command"
        return "$OJUNY_EXIT_USAGE"
    fi

    if ojuny_is_json; then
        jq -cn --arg category "$category" --arg command "$command" --arg summary "$summary" \
            --arg usage "$usage" --arg class "$class" --arg backend "$backend" --arg destructive "$destructive" \
            '{schema:1,command:("help." + $category + "." + $command),ok:true,data:{category:$category,command:$command,summary:$summary,usage:$usage,class:$class,backend:$backend,destructive:($destructive == "1")},meta:{}}'
        return 0
    fi

    printf 'Usage: ojuny %s %s' "$category" "$command"
    [ -n "$usage" ] && [ "$usage" != "-" ] && printf ' %s' "$usage"
    printf '\n\n%s\n\n' "$summary"
    printf 'Class: %s\n' "$class"
    printf 'Backend: %s\n' "$backend"
    [ "$destructive" = "1" ] && printf 'Destructive: yes\n'
    printf '\nOptions:\n'
    printf '  --json   Emit one JSON document\n'
    printf '  --help   Show this help\n'
}

ojuny_help_top() {
    local command="$1"
    local summary usage class backend
    summary="$(ojuny_command_field top "$command" summary)"
    usage="$(ojuny_command_field top "$command" usage)"
    class="$(ojuny_command_field top "$command" class)"
    backend="$(ojuny_command_field top "$command" backend)"

    if [ -z "$summary" ]; then
        ojuny_err "unknown command: $command"
        return "$OJUNY_EXIT_USAGE"
    fi

    if ojuny_is_json; then
        jq -cn --arg command "$command" --arg summary "$summary" --arg usage "$usage" \
            --arg class "$class" --arg backend "$backend" \
            '{schema:1,command:("help." + $command),ok:true,data:{command:$command,summary:$summary,usage:$usage,class:$class,backend:$backend},meta:{}}'
        return 0
    fi

    printf 'Usage: ojuny %s' "$command"
    [ -n "$usage" ] && [ "$usage" != "-" ] && printf ' %s' "$usage"
    printf '\n\n%s\n\n' "$summary"
    printf 'Class: %s\n' "$class"
    printf 'Backend: %s\n' "$backend"
    printf '\nOptions:\n'
    printf '  --json   Emit one JSON document\n'
    printf '  --help   Show this help\n'
}

ojuny_catalog_json() {
    awk -F '\t' '!/^#/ { printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 }' "$(ojuny_commands_file)" |
        jq -R -s '
            split("\n")
            | map(select(length > 0) | split("\t")
            | {
                kind: .[0],
                path: .[1],
                handler: .[2],
                usage: (if .[3] == "-" then "" else .[3] end),
                summary: .[4],
                class: .[5],
                backend: .[6],
                flags: (if .[7] == "-" then "" else .[7] end),
                completion: (if .[8] == "-" then "" else .[8] end),
                aliases: (if .[9] == "-" then "" else .[9] end),
                default: (.[10] == "1"),
                destructive: (.[11] == "1")
            })'
}

ojuny_catalog_human() {
    local kind path usage summary
    ojuny_heading 'Commands'
    while IFS=$'\t' read -r kind path usage summary; do
        printf '  %-24s %s\n' "$path" "$summary"
    done < <(awk -F '\t' '$1 != "cat" { printf "%s\t%s\t%s\t%s\n", $1, $2, $4, $5 }' "$(ojuny_commands_file)")
    printf '\n'
    ojuny_heading 'Categories'
    while IFS=$'\t' read -r path summary; do
        printf '  %-24s %s\n' "$path" "$summary"
    done < <(ojuny_list_categories)
}

ojuny_resolve_category() {
    awk -F '\t' -v wanted="$1" '
        $1 == "cat" && $2 == wanted { print $2; exit }' "$(ojuny_commands_file)"
    awk -F '\t' -v wanted="$1" '
        $1 == "cat" {
            count = split($10, names, ",")
            for (i = 1; i <= count; i++) {
                if (names[i] == wanted) { print $2; exit }
            }
        }' "$(ojuny_commands_file)"
}

ojuny_agents_md() {
    local flake config_dir wireguard_dir version state_dir socket_path
    flake="$(ojuny_flake_root 2>/dev/null || printf 'unknown')"
    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json"
    wireguard_dir="${OJUNY_WIREGUARD_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ojuny/wireguard}"
    version="${OJUNY_VERSION:-unknown}"
    state_dir="$(ojuny_state_dir)"
    socket_path="$(ipc_socket_path)"

    cat <<EOF
# ojuny agent guide

ojuny ${version}

## What this system is

NixOS with Mango and Dux Modular Shell. Configuration is declarative and lives
in the flake. ojuny manages the imperative state that Nix does not own, and it
reports status. It does not edit Nix files except through \`ojuny raw-settings\`.

## Layout

- flake: ${flake}
- nix-settings-gui config: ${config_dir}
- WireGuard watch directory: ${wireguard_dir}
- state directory: ${state_dir}
- IPC socket: ${socket_path}
- patch directory: ${flake}/modules/patches (when the flake provides it)

## Rules

- Use \`--json\` for machine-readable output.
- Use \`--help\` on any category or command.
- Use \`--dry-run\` before destructive actions.
- The CLI never calls sudo. Prefix \`sudo\` for system-scope operations, for
  example \`sudo ojuny service restart NetworkManager\`.
- \`systemctl\` and \`journalctl\` use \`--user\` unless the process is root.
- Persistent values belong in nix-settings-gui: \`ojuny settings <page>\`.
- To edit the module behind a page, use \`ojuny raw-settings <page>\`.
- Do not run \`ojuny flake activate\` without root; it prints a sudo hint.

## Discovery

- \`ojuny commands --json\`: the full catalog.
- \`ojuny status --json\`: system summary.
- \`ojuny print-system-details\`: plaintext support bundle with DE/WM.
- \`ojuny crashes\`: system-wide crash list; \`ojuny crashes latest\` for the newest.
- \`ojuny doctor --json\`: diagnostics.
- \`ojuny ipc path\`: local socket for a persistent session.
- \`ojuny help <category> <command>\`: command help.

## Exit codes

- 0 success
- 2 usage error
- 3 missing dependency
- 4 backend failure
- 5 validation failure
- 6 conflict

## JSON envelope

Success:

\`\`\`json
{"schema":1,"command":"network.status","ok":true,"data":{},"meta":{}}
\`\`\`

Failure:

\`\`\`json
{"schema":1,"command":"vpn.up","ok":false,"error":{"code":3,"message":"...","hint":"..."}}
\`\`\`

## Command map

EOF

    ojuny_catalog_human

    cat <<'EOF'

## Examples

```sh
ojuny status
ojuny wifi list
ojuny wifi connect home-wifi
ojuny vpn up work
ojuny vpn import ~/Downloads/work.conf
ojuny bluetooth connect AA:BB:CC:DD:EE:FF
ojuny sound volume 40
ojuny display brightness set 60
ojuny service status NetworkManager
ojuny logs NetworkManager --since "10 min ago"
ojuny secureboot status
ojuny capture text
ojuny settings displays
ojuny raw-settings displays
ojuny flake update nixpkgs
sudo ojuny flake activate --boot
```
EOF
}

ojuny_agents_json() {
    local flake config_dir wireguard_dir version state_dir socket_path catalog
    flake="$(ojuny_flake_root 2>/dev/null || printf 'unknown')"
    config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json"
    wireguard_dir="${OJUNY_WIREGUARD_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ojuny/wireguard}"
    version="${OJUNY_VERSION:-unknown}"
    state_dir="$(ojuny_state_dir)"
    socket_path="$(ipc_socket_path)"
    catalog="$(ojuny_catalog_json)"

    jq -cn --arg version "$version" --arg flake "$flake" --arg config "$config_dir" \
        --arg wireguard "$wireguard_dir" --arg state "$state_dir" --arg socket "$socket_path" \
        --argjson catalog "$catalog" \
        '{schema:1,command:"print-agent-details",ok:true,data:{version:$version,layout:{flake:$flake,nix_settings_gui:$config,wireguard:$wireguard,state:$state,ipc_socket:$socket},rules:["cli never calls sudo","systemctl and journalctl default to --user unless root","persistent values use settings or raw-settings","json for machines","help for discovery","ipc is local and unprivileged"],catalog:$catalog},meta:{}}'
}
