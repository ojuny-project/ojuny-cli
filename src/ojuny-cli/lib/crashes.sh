ojuny_crashes_dir() {
    printf '%s/crashes\n' "$(ojuny_state_dir)"
}

ojuny_record_crash() {
    local command="$1"
    local status="$2"
    local message="$3"
    local errtext="$4"
    local dir file

    if [ "$status" -lt "$OJUNY_EXIT_BACKEND" ]; then
        return 0
    fi

    dir="$(ojuny_crashes_dir)"
    mkdir -p "$dir"
    chmod 700 "$dir"
    file="$dir/$(date -u +%Y%m%dT%H%M%SZ)-$$.log"

    {
        printf 'ojuny crash\n'
        printf '  time: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '  command: %s\n' "$command"
        printf '  exit: %s\n' "$status"
        printf '  signal: %s\n' "none"
        printf '  host: %s\n' "$(uname -n)"
        printf '  flake: %s\n' "$(ojuny_flake_root 2>/dev/null || printf 'unknown')"
        printf '  message: %s\n' "$message"
        printf '  stderr:\n'
        printf '%s\n' "$errtext" | sed 's/^/    /'
    } | ojuny_redact >"$file"
    chmod 600 "$file"
}

crashes_coredump_json() {
    coredumpctl list --json=short --no-pager 2>/dev/null
}

crashes_list_records() {
    local dir
    dir="$(ojuny_crashes_dir)"
    if [ ! -d "$dir" ]; then
        printf 'no captured crashes\n'
        return 0
    fi

    local index=0 file
    printf 'IDX\tTIME\tCOMMAND\n'
    while IFS= read -r file; do
        index=$((index + 1))
        printf '%s\t%s\t%s\n' "$index" "$(date -r "$file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" \
            "$(awk -F': ' '/  command:/ { print $2; exit }' "$file")"
    done < <(find "$dir" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2-)
}

crashes_list() {
    if command -v coredumpctl >/dev/null 2>&1; then
        local data
        if ! data="$(crashes_coredump_json)"; then
            printf '  hint: sudo ojuny crashes\n' >&2
            crashes_list_records
            return 0
        fi
        case "$data" in
        \[*)
            if ojuny_is_json; then
                jq -cn --argjson data "$data" \
                    '$data | [to_entries[] | {index:(.key + 1), time:(.value.time / 1000000 | floor), pid:.value.pid, sig:.value.sig, exe:.value.exe, corefile:.value.corefile}]'
            else
                printf '%-4s %-19s %-8s %-4s %s\n' 'IDX' 'TIME' 'PID' 'SIG' 'EXE'
                jq -rn --argjson data "$data" \
                    '$data | to_entries[] | "\(.key + 1)\t\(.value.time / 1000000 | floor | strftime("%Y-%m-%d %H:%M:%S"))\t\(.value.pid)\t\(.value.sig)\t\(.value.exe)"' |
                    while IFS=$'\t' read -r idx time pid sig exe; do
                        printf '%-4s %-19s %-8s %-4s %s\n' "$idx" "$time" "$pid" "$sig" "$exe"
                    done
            fi
            return 0
            ;;
        esac
    fi

    crashes_list_records
}

crashes_resolve_pid() {
    local entry="$1"
    local data pid
    data="$(crashes_coredump_json)"
    case "$data" in
    \[*)
        pid="$(jq -rn --argjson data "$data" --argjson index "$entry" '$data[$index - 1].pid // empty')"
        if [ -n "$pid" ]; then
            printf '%s\n' "$pid"
            return 0
        fi
        ;;
    esac
    return 1
}

crashes_latest_record() {
    local dir file
    dir="$(ojuny_crashes_dir)"
    [ -d "$dir" ] || return 1
    file="$(find "$dir" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)"
    [ -n "$file" ] || return 1
    cat "$file"
}

crashes_show_record() {
    local entry="$1"
    local dir file
    dir="$(ojuny_crashes_dir)"
    [ -d "$dir" ] || return 1
    file="$(find "$dir" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr |
        sed -n "${entry}p" | cut -d' ' -f2-)"
    [ -n "$file" ] || return 1
    cat "$file"
}

crashes_show() {
    local entry="$1"
    local output

    if [ "$entry" = "latest" ]; then
        if command -v coredumpctl >/dev/null 2>&1; then
            output="$(coredumpctl info --no-pager 2>/dev/null || true)"
            if [ -n "$output" ]; then
                printf '%s\n' "$output"
                return 0
            fi
        fi
        crashes_latest_record || {
            ojuny_err "no crashes found"
            return "$OJUNY_EXIT_VALIDATION"
        }
        return 0
    fi

    if [[ "$entry" =~ ^[0-9]+$ ]]; then
        local pid
        if pid="$(crashes_resolve_pid "$entry")" && command -v coredumpctl >/dev/null 2>&1; then
            output="$(coredumpctl info --no-pager "$pid" 2>/dev/null || true)"
            if [ -n "$output" ]; then
                printf '%s\n' "$output"
                return 0
            fi
        fi
        crashes_show_record "$entry" || {
            ojuny_err "no crash entry: $entry"
            return "$OJUNY_EXIT_VALIDATION"
        }
        return 0
    fi

    if command -v coredumpctl >/dev/null 2>&1; then
        output="$(coredumpctl info --no-pager "$entry" 2>/dev/null || true)"
        if [ -n "$output" ]; then
            printf '%s\n' "$output"
            return 0
        fi
    fi

    ojuny_err "no crash entry: $entry"
    return "$OJUNY_EXIT_VALIDATION"
}

crashes_cmd() {
    local entry="${1:-}"

    if [ -z "$entry" ]; then
        crashes_list
        return 0
    fi

    crashes_show "$entry"
}
