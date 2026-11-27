settings_cmd() {
    local page="${1:-}"
    local args=()

    if [ "$page" = "--list" ]; then
        ojuny_settings_pages
        return 0
    fi

    ojuny_require_command nix-settings-gui

    if [ -n "$page" ]; then
        args=(--page "$page")
    fi

    if ojuny_is_dry_run; then
        ojuny_exec nix-settings-gui "${args[@]}"
        return 0
    fi

    if ojuny_is_json; then
        jq -cn --arg page "$page" '{schema:1,command:"settings",ok:true,data:{launched:true,page:$page},meta:{}}'
    fi

    setsid nix-settings-gui "${args[@]}" >/dev/null 2>&1 &
}

raw_settings_cmd() {
    local page="${1:-}"

    if [ "$page" = "--list" ]; then
        if ojuny_is_json; then
            ojuny_settings_pages | jq -Rn '{pages: [inputs | split("\t") | {page: .[0], file: .[1]}]}'
        else
            ojuny_settings_pages_table
        fi
        return 0
    fi

    if [ -z "$page" ]; then
        ojuny_err "usage: ojuny raw-settings [--list|<page>]"
        printf '  available:\n' >&2
        ojuny_settings_pages_table | sed 's/^/    /' >&2
        return "$OJUNY_EXIT_USAGE"
    fi

    local file
    file="$(ojuny_find_settings_page "$page")"
    if [ -z "$file" ]; then
        ojuny_err "no settings page matches: $page"
        printf '  available:\n' >&2
        ojuny_settings_pages_table | sed 's/^/    /' >&2
        return "$OJUNY_EXIT_VALIDATION"
    fi

    local editor="${VISUAL:-${EDITOR:-nano}}"

    if ojuny_is_json; then
        jq -cn --arg page "$page" --arg file "$file" \
            '{schema:1,command:"raw-settings",ok:true,data:{opened:true,page:$page,file:$file},meta:{}}'
        return 0
    fi

    if ojuny_is_dry_run; then
        ojuny_exec "$editor" "$file"
        return 0
    fi

    "$editor" "$file"
}

ojuny_settings_menus() {
    local flake
    flake="$(ojuny_flake_root)" || return

    find "$flake" -type f -name '*.nix' \
        -not -path '*/.git/*' \
        -not -path '*/result*' \
        -not -path '*/node_modules/*' \
        -not -name '_*' 2>/dev/null |
        while IFS= read -r file; do
            stem="$(basename "$file" .nix)"
            awk -v file="$file" -v stem="$stem" '
                BEGIN { inside = 0; found = 0 }
                /@menu/ {
                    if ($0 ~ /displayname[[:space:]]*=/) {
                        line = $0
                        sub(/.*displayname[[:space:]]*=[[:space:]]*"/, "", line)
                        sub(/".*/, "", line)
                        print line "\t" stem "\t" file
                        found = 1
                        inside = 0
                        next
                    }
                    inside = 1
                    found = 0
                    next
                }
                inside && /displayname[[:space:]]*=/ {
                    line = $0
                    sub(/.*displayname[[:space:]]*=[[:space:]]*"/, "", line)
                    sub(/".*/, "", line)
                    print line "\t" stem "\t" file
                    found = 1
                    inside = 0
                    next
                }
                inside && /\*\// {
                    if (!found) print stem "\t" stem "\t" file
                    inside = 0
                }
                END {
                    if (inside && !found) print stem "\t" stem "\t" file
                }
            ' "$file"
        done
}

ojuny_settings_pages() {
    ojuny_settings_menus | awk -F '\t' '{ print $1 "\t" $3 }' | sort -u
}

ojuny_settings_pages_table() {
    ojuny_settings_pages | awk -F '\t' '
        BEGIN { width = 4 }
        {
            rows[NR] = $1 "\t" $2
            if (length($1) > width) width = length($1)
        }
        END {
            printf "%-*s  %s\n", width, "PAGE", "FILE"
            for (i = 1; i <= NR; i++) {
                split(rows[i], cell, "\t")
                printf "%-*s  %s\n", width, cell[1], cell[2]
            }
        }'
}

ojuny_find_settings_page() {
    local pattern="$1"
    local exact

    exact="$(ojuny_settings_menus | awk -F '\t' -v pattern="$pattern" '
        function normal(value) {
            value = tolower(value)
            gsub(/[[:space:]_-]/, "", value)
            return value
        }
        BEGIN {
            wanted = normal(pattern)
            if (wanted == "") exit
        }
        {
            if (normal($1) == wanted || normal($2) == wanted || normal($3) == wanted) {
                print $3
                exit
            }
        }
    ')"
    if [ -n "$exact" ]; then
        printf '%s\n' "$exact"
        return 0
    fi

    ojuny_settings_menus | sort -t $'\t' -k1,1 | awk -F '\t' -v pattern="$pattern" '
        function normal(value) {
            value = tolower(value)
            gsub(/[[:space:]_-]/, "", value)
            return value
        }
        BEGIN {
            wanted = normal(pattern)
            if (wanted == "") exit
        }
        {
            if (index(normal($1), wanted) || index(normal($2), wanted) || index(normal($3), wanted)) {
                print $3
                exit
            }
        }
    '
}
