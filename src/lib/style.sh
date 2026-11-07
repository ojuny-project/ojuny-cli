if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${CLICOLOR:-1}" != "0" ] && [ "${OJUNY_NO_COLOR:-0}" -eq 0 ]; then
    OJUNY_C_RESET=$'\033[0m'
    OJUNY_C_BOLD=$'\033[1m'
    OJUNY_C_DIM=$'\033[2m'
    OJUNY_C_RED=$'\033[31m'
    OJUNY_C_GREEN=$'\033[32m'
    OJUNY_C_YELLOW=$'\033[33m'
    OJUNY_C_CYAN=$'\033[36m'
else
    OJUNY_C_RESET=""
    OJUNY_C_BOLD=""
    OJUNY_C_DIM=""
    OJUNY_C_RED=""
    OJUNY_C_GREEN=""
    OJUNY_C_YELLOW=""
    OJUNY_C_CYAN=""
fi

ojuny_style() {
    local color="$1"
    shift
    printf '%s%s%s' "$color" "$*" "$OJUNY_C_RESET"
}

ojuny_heading() {
    printf '%s\n' "$(ojuny_style "$OJUNY_C_CYAN$OJUNY_C_BOLD" "$*")"
}

ojuny_dim() {
    printf '%s' "$(ojuny_style "$OJUNY_C_DIM" "$*")"
}

ojuny_ok() {
    ojuny_is_quiet && return 0
    printf '%s %s\n' "$(ojuny_style "$OJUNY_C_GREEN" "ok")" "$*"
}

ojuny_warn() {
    printf '%s %s\n' "$(ojuny_style "$OJUNY_C_YELLOW" "warn")" "$*" >&2
}

ojuny_error() {
    printf '%s %s\n' "$(ojuny_style "$OJUNY_C_RED" "error")" "$*" >&2
}

ojuny_kv_block() {
    local line key value width=0
    local -a lines=()

    while IFS=$'\t' read -r key value; do
        [ -n "$key" ] || continue
        lines+=("$key"$'\t'"$value")
        [ "${#key}" -gt "$width" ] && width=${#key}
    done

    for line in "${lines[@]}"; do
        key="${line%%$'\t'*}"
        value="${line#*$'\t'}"
        printf '  %s  %s\n' "$(printf '%-*s' "$width" "$key")" "$value"
    done
}

ojuny_table() {
    local line width=0 cell
    local -a rows=()

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        rows+=("$line")
    done

    for line in "${rows[@]}"; do
        IFS=$'\t' read -r -a cells <<<"$line"
        for cell in "${cells[@]}"; do
            [ "${#cell}" -gt "$width" ] && width=${#cell}
        done
    done

    for line in "${rows[@]}"; do
        IFS=$'\t' read -r -a cells <<<"$line"
        printf '  '
        for cell in "${cells[@]}"; do
            printf '%-*s  ' "$width" "$cell"
        done
        printf '\n'
    done
}
