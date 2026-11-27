ojuny_crashes_dir() {
    printf '%s/crashes\n' "$(ojuny_state_dir)"
}

ojuny_record_crash() {
    local command="$1"
    local status="$2"
    local message="$3"
    local errtext="$4"
    local dir file

    case "$status" in
    "$OJUNY_EXIT_BACKEND") ;;
    *)
        [ "$status" -ge 128 ] || return 0
        ;;
    esac

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

crashes_raven_dir() {
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        local home
        home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
        [ -n "$home" ] || return 1
        printf '%s/.local/state/ojuny/raven\n' "$home"
        return 0
    fi
    printf '%s/ojuny/raven\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

crashes_raven_logs() {
    local dir
    dir="$(crashes_raven_dir)" || return 0
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type f \( -name '*failure.log' -o -name '*running.log' \) -printf '%T@ %p\n' 2>/dev/null |
        sort -nr | cut -d' ' -f2-
}

crashes_raven_hint() {
    local log
    log="$(crashes_raven_logs | sed -n '1p')"
    [ -n "$log" ] || return 0
    if ojuny_is_json; then
        return 0
    fi
    printf '  hint: a session freeze is a hang, not a coredump; read %s\n' "$log" >&2
}

crashes_list_records() {
    local dir
    dir="$(ojuny_crashes_dir)"
    if [ ! -d "$dir" ]; then
        return 0
    fi

    local index=0 file
    while IFS= read -r file; do
        index=$((index + 1))
        printf '%-4s %-19s %s\n' "$index" "$(date -r "$file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" \
            "$(awk -F': ' '/  command:/ { print $2; exit }' "$file")"
    done < <(find "$dir" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2-)
}

crashes_list_raven() {
    local index=0 file
    local logs
    logs="$(crashes_raven_logs)"
    [ -n "$logs" ] || return 0

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        index=$((index + 1))
        case "$file" in
        *-running.log) note=" (no exit recorded)" ;;
        *) note="" ;;
        esac
        printf '%-4s %-19s %s\n' "R$index" \
            "$(date -r "$file" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" "$file$note"
    done <<EOF
$logs
EOF
}

crashes_coredump_table() {
    local data="$1"
    printf '%-4s %-19s %-8s %-4s %s\n' 'IDX' 'TIME' 'PID' 'SIG' 'EXE'
    jq -rn --argjson data "$data" \
        '$data | to_entries[] | "\(.key + 1)\t\(.value.time / 1000000 | floor | strftime("%Y-%m-%d %H:%M:%S"))\t\(.value.pid)\t\(.value.sig)\t\(.value.exe)"' |
        while IFS=$'\t' read -r idx time pid sig exe; do
            printf '%-4s %-19s %-8s %-4s %s\n' "$idx" "$time" "$pid" "$sig" "$exe"
        done
}

crashes_list() {
    if ojuny_is_json; then
        crashes_list_json
        return 0
    fi

    printf 'COREDUMPS\n'
    if command -v coredumpctl >/dev/null 2>&1; then
        local data
        if data="$(crashes_coredump_json)"; then
            case "$data" in
            \[*) crashes_coredump_table "$data" ;;
            *) printf '  no coredumps\n' ;;
            esac
        else
            printf '  hint: sudo ojuny crashes\n' >&2
        fi
    else
        printf '  coredumpctl is not available\n'
    fi

    printf '\nCAPTURED FAILURES\n'
    printf '%-4s %-19s %s\n' 'IDX' 'TIME' 'COMMAND'
    crashes_list_records

    if [ -n "$(crashes_raven_logs)" ]; then
        printf '\nRAVEN FAILURES\n'
        printf '%-4s %-19s %s\n' 'IDX' 'TIME' 'FILE'
        crashes_list_raven
    fi

    crashes_raven_hint
}

crashes_list_json() {
    local coredumps='[]'
    local data records raven index=0 file

    if command -v coredumpctl >/dev/null 2>&1; then
        if data="$(crashes_coredump_json)"; then
            case "$data" in
            \[*) coredumps="$data" ;;
            esac
        fi
    fi

    records="$(
        if [ -d "$(ojuny_crashes_dir)" ]; then
            find "$(ojuny_crashes_dir)" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null |
                sort -nr | cut -d' ' -f2-
        fi |
            while IFS= read -r file; do
                index=$((index + 1))
                printf '%s\t%s\t%s\n' "$index" "$(date -r "$file" +%s 2>/dev/null || printf '0')" \
                    "$(awk -F': ' '/  command:/ { print $2; exit }' "$file")"
            done |
            jq -Rn '[inputs | split("\t") | {index: (.[0] | tonumber), time: (.[1] | tonumber), command: .[2]}]'
    )"
    [ -n "$records" ] || records='[]'

    index=0
    raven="$(
        crashes_raven_logs |
            while IFS= read -r file; do
                index=$((index + 1))
                printf '%s\t%s\t%s\n' "$index" "$(date -r "$file" +%s 2>/dev/null || printf '0')" "$file"
            done |
            jq -Rn '[inputs | split("\t") | {index: (.[0] | tonumber), time: (.[1] | tonumber), file: .[2]}]'
    )"
    [ -n "$raven" ] || raven='[]'

    jq -cn --argjson coredumps "$coredumps" --argjson records "$records" --argjson raven "$raven" \
        '{coredumps: ($coredumps | to_entries | map({index:(.key + 1), time:(.value.time / 1000000 | floor), pid:.value.pid, sig:.value.sig, exe:.value.exe, corefile:.value.corefile})), captured: $records, raven: $raven}'
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

crashes_latest_record_path() {
    local dir
    dir="$(ojuny_crashes_dir)"
    [ -d "$dir" ] || return 1
    find "$dir" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null |
        sort -nr | sed -n '1p' | cut -d' ' -f2-
}

crashes_latest_record() {
    local file
    file="$(crashes_latest_record_path)" || return 1
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

crashes_show_raven() {
    local entry="$1"
    local file
    if [ "$entry" = "raven" ]; then
        file="$(crashes_raven_logs | sed -n '1p')"
    else
        file="$(crashes_raven_logs | sed -n "${entry}p")"
    fi
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

        local record raven
        record="$(crashes_latest_record_path || true)"
        raven="$(crashes_raven_logs | sed -n '1p')"
        if [ -n "$record" ] && [ -n "$raven" ]; then
            if [ "$record" -nt "$raven" ]; then
                cat "$record"
            else
                cat "$raven"
            fi
            return 0
        fi
        if [ -n "$raven" ]; then
            cat "$raven"
            return 0
        fi
        crashes_latest_record || {
            ojuny_err "no crashes found"
            return "$OJUNY_EXIT_VALIDATION"
        }
        return 0
    fi

    if [[ "$entry" =~ ^[Rr]([0-9]+)$ ]]; then
        crashes_show_raven "${BASH_REMATCH[1]}" || {
            ojuny_err "no Raven failure entry: $entry"
            return "$OJUNY_EXIT_VALIDATION"
        }
        return 0
    fi

    if [ "$entry" = "raven" ]; then
        crashes_show_raven raven || {
            ojuny_err "no Raven failure log"
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
